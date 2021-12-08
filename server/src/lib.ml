[@@@warning "-27"]

open Core
open Lwt.Infix
open Cohttp_lwt_unix

(* Data retrieval logic *)

let get (url : string) : string Lwt.t =
  Client.get (Uri.of_string url) >>= fun (_res, body) -> body |> Cohttp_lwt.Body.to_string
  [@@coverage off]
;;

(* 
  Shape response body into proper string format to be saved to csv file.
  Add first id column with indices starting at 0
  Aggregate the 5 chunks of 1000 lines each together
*)
let preprocess_csv ~(title : string) ~(header : string) ~(body_list : string list)
    : string
  =
  let str =
    List.foldi body_list ~init:[] ~f:(fun idx acc body ->
        let json = Yojson.Basic.from_string body in
        let j = Yojson.Basic.Util.filter_list [ json ] |> List.hd_exn in
        let res =
          List.mapi j ~f:(fun i item ->
              let ls = Yojson.Basic.Util.to_list item in
              Int.to_string (i + (1000 * idx))
              :: List.map ls ~f:(fun x ->
                     let s = Yojson.Basic.to_string x in
                     (* Remove double quotation marks from string items *)
                     match String.find s ~f:(fun c -> Char.( = ) c '\"') with
                     | None -> s
                     | _ -> String.drop_prefix (String.drop_suffix s 1) 1))
        in
        List.append acc res)
  in
  List.fold
    ~init:(title ^ "\n" ^ header)
    str
    ~f:(fun acc item -> acc ^ "\n" ^ String.concat ~sep:"," item)
  [@@coverage off]
;;

let preprocess_candlesticks (data : string) : float array array =
  let json = Yojson.Basic.from_string data in
  let j = Yojson.Basic.Util.filter_list [ json ] |> List.hd_exn in
  let res =
    Array.of_list
    @@ List.mapi j ~f:(fun i item ->
           let ls = Yojson.Basic.Util.to_list item in
           Array.of_list
           @@ List.foldi ls ~init:[] ~f:(fun i' acc x ->
                  match i' with
                  | 1 | 5 | 7 | 8 | 9 | 10 ->
                    let s = Yojson.Basic.to_string x in
                    (* Remove double quotation marks from string items *)
                    (match String.find s ~f:(fun c -> Char.( = ) c '\"') with
                    | None -> acc @ [ Float.of_string s ]
                    | _ ->
                      acc
                      @ [ Float.of_string @@ String.drop_prefix (String.drop_suffix s 1) 1
                        ])
                  | _ -> acc))
  in
  (* Array.iter res ~f:(fun arr ->
      print_endline
      @@ List.to_string ~f:(fun x -> Float.to_string x ^ ",") (Array.to_list arr)); *)
  res
;;

let get_candlesticks
    ~(symbol : string)
    ~(interval : string)
    ~(start_time : int)
    ~(end_time : int)
    : string Lwt.t
  =
  get
    (Printf.sprintf
       "https://api.binance.com/api/v3/klines?symbol=%s&interval=%s&startTime=%d&endTime=%d&limit=1000"
       symbol
       interval
       start_time
       end_time)
  [@@coverage off]
;;

let get_btc_data ~(symbol : string) ~(interval : string) ~(start_time : int) : string =
  (*
    Each period is 1000 * 5 = 5000 minutes, equivalently 300000000 milliseconds
    and corresponds to 1000 lines of csv datapoints.
  *)
  let period = 300000000 in
  let body_list =
    List.map
      (* Call API endpoint 5 times, each generating 1000 lines of csv datapoints *)
      (List.init 5 ~f:(fun i -> start_time + (i * period)))
      ~f:(fun x ->
        Lwt_main.run
        @@ get_candlesticks ~symbol ~interval ~start_time:x ~end_time:(x + period))
  in
  preprocess_csv
    ~title:"BTCUSDT-5m-5klines"
    ~header:
      "id,open time,open,high,low,close,volume,close time,quote asset volume,number of \
       trades,taker buy base asset volume,taker buy quote asset volume,ignore"
    ~body_list
  [@@coverage off]
;;

let save_csv ~(csv : string) ~(file : string) =
  Csv.input_all @@ Csv.of_string csv |> Csv.save file
  [@@coverage off]
;;

let get_features () : unit =
  let csv = get_btc_data ~symbol:"BTCUSDT" ~interval:"5m" ~start_time:1635724800000 in
  save_csv ~csv ~file:(Sys.getcwd () ^ "/BTCUSDT-5m-5klines.csv")
  [@@coverage off]
;;

(* Game Logic *)

module DB = struct
  [@@@coverage off]

  open Postgresql

  let conn =
    try
      new connection ~host:"localhost" ~port:"5432" ~dbname:"testdb" ~user:"postgres" ()
    with
    | Error e ->
      prerr_endline (string_of_error e);
      exit 34
    | e ->
      prerr_endline (Exn.to_string e);
      exit 35
  ;;

  let create_table () : unit =
    conn#exec
      ~expect:[ Command_ok ]
      "create table transactions (id serial primary key, usd_bal float4, btc_bal float4, \
       usd_amount float4, btc_amount float4, transaction_type text)"
    |> ignore
  ;;

  let delete_table () : unit =
    conn#exec ~expect:[ Command_ok ] "drop table if exists transactions cascade" |> ignore
  ;;

  let write
      ~(usd_bal : float)
      ~(btc_bal : float)
      ~(usd_amount : float)
      ~(btc_amount : float)
      ~(transaction_type : string)
      : unit
    =
    let param_types =
      Postgresql.
        [| oid_of_ftype FLOAT4
         ; oid_of_ftype FLOAT4
         ; oid_of_ftype FLOAT4
         ; oid_of_ftype FLOAT4
         ; oid_of_ftype TEXT
        |]
    in
    conn#exec
      ~expect:[ Command_ok ]
      ~param_types
      ~params:
        [| Float.to_string usd_bal
         ; Float.to_string btc_bal
         ; Float.to_string usd_amount
         ; Float.to_string btc_amount
         ; transaction_type
        |]
      "insert into transactions (usd_bal, btc_bal, usd_amount, btc_amount, \
       transaction_type) values ($1, $2, $3, $4, $5)"
    |> ignore
  ;;

  let read (query : string) : string list list =
    let result = conn#exec ~expect:[ Tuples_ok ] query in
    result#get_all_lst
  ;;
end

module Game = struct
  type transaction =
    { id : int
    ; usd_bal : float
    ; btc_bal : float
    ; usd_amount : float
    ; btc_amount : float
    ; transaction_type : string
    }

  type res =
    { usd_bal : float
    ; btc_bal : float
    ; msg : string
    }

  let get_latest () : transaction =
    let res =
      DB.read "select * from transactions order by id desc limit 1" |> List.hd_exn
    in
    match res with
    | [ id; usd_bal; btc_bal; usd_amount; btc_amount; transaction_type ] ->
      { id = Int.of_string id
      ; usd_bal = Float.of_string usd_bal
      ; btc_bal = Float.of_string btc_bal
      ; usd_amount = Float.of_string usd_amount
      ; btc_amount = Float.of_string btc_amount
      ; transaction_type
      }
    | _ -> failwith "unreachable"
    [@@coverage off]
  ;;

  let set_latest
      ~(usd_bal : float)
      ~(btc_bal : float)
      ~(usd_amount : float)
      ~(btc_amount : float)
      ~(transaction_type : string)
      : unit
    =
    DB.write ~usd_bal ~btc_bal ~usd_amount ~btc_amount ~transaction_type
    [@@coverage off]
  ;;

  let init () : unit =
    DB.delete_table ();
    DB.create_table ();
    DB.write
      ~usd_bal:10000.
      ~btc_bal:0.
      ~usd_amount:0.
      ~btc_amount:0.
      ~transaction_type:"INIT"
    [@@coverage off]
  ;;

  let preprocess_real_price (data : string) : float =
    let json = Yojson.Basic.from_string data in
    [ json ]
    |> Yojson.Basic.Util.filter_member "price"
    |> List.hd_exn
    |> Yojson.Basic.Util.to_string
    |> Float.of_string
  ;;

  let get_real_price () : string Lwt.t =
    get "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT"
    [@@coverage off]
  ;;

  let buy ~(btc : float) ~(price : float) : res =
    let n = btc *. price in
    let { id = _
        ; usd_bal = prev_usd_bal
        ; btc_bal = prev_btc_bal
        ; usd_amount = _
        ; btc_amount = _
        ; transaction_type = _
        }
      =
      get_latest ()
    in
    if Float.( < ) prev_usd_bal n
    then
      { usd_bal = prev_usd_bal
      ; btc_bal = prev_btc_bal
      ; msg = "Not enough dollars in wallet!"
      }
    else (
      let usd_bal, btc_bal = prev_usd_bal -. n, prev_btc_bal +. btc in
      set_latest
        ~usd_bal
        ~btc_bal
        ~btc_amount:btc
        ~usd_amount:n
        ~transaction_type:"BUY_REAL";
      { usd_bal; btc_bal; msg = Printf.sprintf "You bought %f Bitcoin at $%f" btc n })
    [@@coverage off]
  ;;

  let sell ~(btc : float) ~(price : float) : res =
    let n = btc *. price in
    let { id = _
        ; usd_bal = prev_usd_bal
        ; btc_bal = prev_btc_bal
        ; usd_amount = _
        ; btc_amount = _
        ; transaction_type = _
        }
      =
      get_latest ()
    in
    if Float.( < ) prev_btc_bal btc
    then
      { usd_bal = prev_usd_bal
      ; btc_bal = prev_btc_bal
      ; msg = "Not enough Bitcoin in wallet!"
      }
    else (
      let usd_bal, btc_bal = prev_usd_bal +. n, prev_btc_bal -. btc in
      set_latest
        ~usd_bal
        ~btc_bal
        ~btc_amount:btc
        ~usd_amount:n
        ~transaction_type:"SELL_REAL";
      { usd_bal; btc_bal; msg = Printf.sprintf "You sold %f Bitcoin at $%f" btc n })
    [@@coverage off]
  ;;

  let convert ~(btc : float) ~(price : float) : float = btc *. price
end

open Torch

module Forecast = struct
  [@@@coverage off]

  let x_std x x_min x_max = (x -. x_min) /. (x_max -. x_min)

  let x_scaled x_std = x_std *. 2.0 +. (-1.0)

  let data_min = [| 58601.01; 21.32; 1308176.69; 1412.; 7.179; 457771.89 |]

  let data_max = [| 68734.26; 3108.785; 199045154.; 95357.; 1130.90; 69703190.3 |]

  let normalize (input : float array array) : float array array =
    let normalize_single_point (x : float array) = 
      let index = ref 0 in 
      let f v = 
        let x_min = Array.get data_min !index in 
        let x_max = Array.get data_max !index in 
        index := !index + 1;
        x_scaled (x_std v x_min x_max)
      in 
      Array.map ~f x
    in 
    Array.map ~f:normalize_single_point input;;

  let denormalize (input : float) : float =
    let max = 68734.26 in
    let min = 58601.01 in
    let max_min_descale_float x = ((x +. 1.0) /. 2.0 *. (max -. min)) +. min in
    max_min_descale_float input
  ;;

  let predict (input : float array array) : float =
    let input_tensor = Tensor.of_float2 (normalize input) in
    (*let cwd = Sys.getcwd () in *)
    let model = Module.load "../forecasting/model/model.pt" in
    Module.forward model [ input_tensor ] |> Tensor.to_float0_exn |> denormalize
  ;;
end
