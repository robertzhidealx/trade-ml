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
  csv |> Csv.of_string |> Csv.input_all |> Csv.save file
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
       usd_amount float4, btc_amount float4, transaction_time int8, transaction_type \
       text)"
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
      ~(transaction_time : int64)
      ~(transaction_type : string)
      : unit
    =
    let param_types =
      Postgresql.
        [| oid_of_ftype FLOAT4
         ; oid_of_ftype FLOAT4
         ; oid_of_ftype FLOAT4
         ; oid_of_ftype FLOAT4
         ; oid_of_ftype INT8
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
         ; Int64.to_string transaction_time
         ; transaction_type
        |]
      "insert into transactions (usd_bal, btc_bal, usd_amount, btc_amount, \
       transaction_time, transaction_type) values ($1, $2, $3, $4, $5, $6)"
    |> ignore
  ;;

  let read (query : string) : string list list =
    let result = conn#exec ~expect:[ Tuples_ok ] query in
    result#get_all_lst
  ;;
end

module Game = struct
  [@@@coverage off]

  type transaction =
    { id : int
    ; usd_bal : float
    ; btc_bal : float
    ; usd_amount : float
    ; btc_amount : float
    ; transaction_time : int64
    ; transaction_type : string
    }
  [@@deriving yojson]

  type transaction_list = transaction list [@@deriving yojson]

  type wallet =
    { usd_bal : float
    ; btc_bal : float
    ; msg : string
    }
  [@@deriving yojson]

  type 'data response =
    { data : 'data
    ; code : int
    }
  [@@deriving yojson]

  type conversion_response =
    { btc : float
    ; real_usd_value : float
    ; predicted_usd_value : float
    }
  [@@deriving yojson]

  let get_latest () : transaction =
    let res =
      DB.read "select * from transactions order by id desc limit 1" |> List.hd_exn
    in
    match res with
    | [ id; usd_bal; btc_bal; usd_amount; btc_amount; transaction_time; transaction_type ]
      ->
      { id = Int.of_string id
      ; usd_bal = Float.of_string usd_bal
      ; btc_bal = Float.of_string btc_bal
      ; usd_amount = Float.of_string usd_amount
      ; btc_amount = Float.of_string btc_amount
      ; transaction_time = Int64.of_string transaction_time
      ; transaction_type
      }
    | _ -> failwith "unreachable"
  ;;

  let get_latest_to_response (t : transaction) : string =
    Yojson.Safe.to_string
    @@ response_to_yojson (fun row -> transaction_to_yojson row) { data = t; code = 200 }
  ;;

  let set_latest
      ~(usd_bal : float)
      ~(btc_bal : float)
      ~(usd_amount : float)
      ~(btc_amount : float)
      ~(transaction_time : int64)
      ~(transaction_type : string)
      : unit
    =
    DB.write ~usd_bal ~btc_bal ~usd_amount ~btc_amount ~transaction_time ~transaction_type
  ;;

  let init ~(transaction_time : int64) : string =
    DB.delete_table ();
    DB.create_table ();
    DB.write
      ~usd_bal:10000.
      ~btc_bal:0.
      ~usd_amount:0.
      ~btc_amount:0.
      ~transaction_time
      ~transaction_type:"INIT";
    let w = { usd_bal = 10000.; btc_bal = 0.; msg = "Initialized game!" } in
    Yojson.Safe.to_string
    @@ response_to_yojson (fun row -> wallet_to_yojson row) { data = w; code = 200 }
  ;;

  let preprocess_real_price (data : string) : float =
    let json = Yojson.Basic.from_string data in
    [ json ]
    |> Yojson.Basic.Util.filter_member "price"
    |> List.hd_exn
    |> Yojson.Basic.Util.to_string
    |> Float.of_string
    [@@coverage on]
  ;;

  let get_real_price () : string Lwt.t =
    get "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT"
  ;;

  let buy ~(btc : float) ~(price : float) ~(transaction_time : int64) : string =
    if Float.( = ) btc 0.
    then failwith "Number of Bitcoin must be > 0"
    else (
      let n = btc *. price in
      let { id = _
          ; usd_bal = prev_usd_bal
          ; btc_bal = prev_btc_bal
          ; usd_amount = _
          ; btc_amount = _
          ; transaction_time = _
          ; transaction_type = _
          }
        =
        get_latest ()
      in
      if Float.( < ) prev_usd_bal n
      then failwith "Not enough dollars in wallet"
      else (
        let usd_bal, btc_bal = prev_usd_bal -. n, prev_btc_bal +. btc in
        set_latest
          ~usd_bal
          ~btc_bal
          ~btc_amount:btc
          ~usd_amount:n
          ~transaction_time
          ~transaction_type:"BUY";
        let w =
          { usd_bal; btc_bal; msg = Printf.sprintf "You bought %f Bitcoin at $%f" btc n }
        in
        Yojson.Safe.to_string
        @@ response_to_yojson (fun row -> wallet_to_yojson row) { data = w; code = 200 }))
  ;;

  let sell ~(btc : float) ~(price : float) ~(transaction_time : int64) : string =
    if Float.( = ) btc 0.
    then failwith "Number of Bitcoin must be > 0"
    else (
      let n = btc *. price in
      let { id = _
          ; usd_bal = prev_usd_bal
          ; btc_bal = prev_btc_bal
          ; usd_amount = _
          ; btc_amount = _
          ; transaction_time = _
          ; transaction_type = _
          }
        =
        get_latest ()
      in
      if Float.( < ) prev_btc_bal btc
      then failwith "Not enough Bitcoin in wallet"
      else (
        let usd_bal, btc_bal = prev_usd_bal +. n, prev_btc_bal -. btc in
        set_latest
          ~usd_bal
          ~btc_bal
          ~btc_amount:btc
          ~usd_amount:n
          ~transaction_time
          ~transaction_type:"SELL";
        let w =
          { usd_bal; btc_bal; msg = Printf.sprintf "You sold %f Bitcoin at $%f" btc n }
        in
        Yojson.Safe.to_string
        @@ response_to_yojson (fun row -> wallet_to_yojson w) { data = w; code = 200 }))
    [@@coverage off]
  ;;

  let convert ~(btc : float) ~(real_price : float) ~(predicted_price : float) : string =
    let real, predicted = btc *. real_price, btc *. predicted_price in
    let conversion = { btc; real_usd_value = real; predicted_usd_value = predicted } in
    Yojson.Safe.to_string
    @@ response_to_yojson
         (fun item -> conversion_response_to_yojson item)
         { data = conversion; code = 200 }
    [@@coverage on]
  ;;

  let get_history () : string =
    let res = DB.read "select * from transactions" in
    let hist =
      List.fold res ~init:[] ~f:(fun acc row ->
          match row with
          | [ id; usd_bal; btc_bal; usd_amount; btc_amount; time; transaction_type ] ->
            { id = Int.of_string id
            ; usd_bal = Float.of_string usd_bal
            ; btc_bal = Float.of_string btc_bal
            ; usd_amount = Float.of_string usd_amount
            ; btc_amount = Float.of_string btc_amount
            ; transaction_time = Int64.of_string time
            ; transaction_type
            }
            :: acc
          | _ -> acc)
    in
    Yojson.Safe.to_string
    @@ response_to_yojson
         (fun row -> transaction_list_to_yojson row)
         { data = hist; code = 200 }
  ;;
end

module Forecast = struct
  open Torch

  let x_std x x_min x_max = (x -. x_min) /. (x_max -. x_min)
  let x_scaled x_std = (x_std *. 2.0) +. -1.0
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
    Array.map ~f:normalize_single_point input
  ;;

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
    [@@coverage off]
  ;;
end

module Visualization = struct
  [@@@coverage off]

  type 'data response =
    { data : 'data
    ; code : int
    }
  [@@deriving yojson]

  type single_point =
    { transaction_time : int
    ; btc_price : float
    ; total_assets : float
    }
  [@@deriving yojson]

  type point_list = single_point list [@@deriving yojson]

  let get_past_transcations () =
    let raw =
      List.rev
      @@ DB.read "select * from transactions ORDER BY transaction_time DESC limit 31"
    in
    let f (row : string list) =
      match row with
      | [ id; usd_bal; btc_bal; usd_amount; btc_amount; time; transaction_type ] ->
        let price = Float.of_string usd_amount /. Float.of_string btc_amount in
        { transaction_time = Int.of_string time
        ; btc_price = price
        ; total_assets = Float.of_string usd_bal +. (Float.of_string btc_bal *. price)
        }
      | _ -> failwith "Row format is wrong."
    in
    List.map ~f raw |> (Fn.flip List.drop) 1
  ;;

  let grab_data () =
    let list = get_past_transcations () in
    Yojson.Safe.to_string
    @@ response_to_yojson
         (fun row -> point_list_to_yojson row)
         { data = list; code = 200 }
  ;;
end
