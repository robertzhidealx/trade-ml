[@@@warning "-27"]

open Core
open Lwt
open Cohttp_lwt_unix

(* Data retrieval logic *)

let get (url : string) : string t =
  Client.get (Uri.of_string url) >>= fun (_res, body) -> body |> Cohttp_lwt.Body.to_string
;;

(* 
  Shape response body into proper string format to be saved to csv file.
  Add first id column with indices starting at 0
  Aggregate the 5 chunks of 1000 lines each together
*)
let preprocess ~(title : string) ~(header : string) ~(body_list : string list) : string =
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
;;

(*
  Each period is 1000 * 5 = 5000 minutes, equivalently 300000000 milliseconds
  and corresponds to 1000 lines of csv datapoints.
*)
let period : int = 300000000

let get_btc_data ~(symbol : string) ~(interval : string) ~(start_time : int) : string =
  let body_list =
    List.map
      (* Call API endpoint 5 times, each generating 1000 lines of csv datapoints *)
      (List.init 5 ~f:(fun i -> start_time + (i * period)))
      ~f:(fun x ->
        Lwt_main.run
        @@ get
             ("https://api.binance.com/api/v3/klines?symbol="
             ^ symbol
             ^ "&interval="
             ^ interval
             ^ "&startTime="
             ^ Int.to_string x
             ^ "&endTime="
             ^ Int.to_string (x + period)
             ^ "&limit=1000"))
  in
  preprocess
    ~title:"BTCUSDT-5m-5klines"
    ~header:
      "id,open time,open,high,low,close,volume,close time,quote asset volume,number of \
       trades,taker buy base asset volume,taker buy quote asset volume,ignore"
    ~body_list
;;

let save_csv ~(csv : string) ~(file : string) =
  Csv.input_all @@ Csv.of_string csv |> Csv.save file
;;

let get_features () : unit =
  let csv = get_btc_data ~symbol:"BTCUSDT" ~interval:"5m" ~start_time:1635724800000 in
  save_csv ~csv ~file:(Sys.getcwd () ^ "/BTCUSDT-5m-5klines.csv")
;;

(* let preprocess (_data : string) : string =
  Yojson.Basic.to_string @@ `List [ `List [ `String "hi"; `String "world" ] ]
;; *)

(* Function to load data from a csv file *)
(* let from_csv () = Csv.print @@ Csv.load (Sys.getcwd () ^ "/BTCUSD-1m-21d.csv") *)

(* Game Logic *)

module DB = struct
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
    { usd_bal : float
    ; btc_bal : float
    ; usd_amount : float
    ; btc_amount : float
    ; transaction_type : string
    }

  type res =
    { usd_bal : float
    ; btc_bal : float
    ; message : string
    }

  let get_latest () : transaction =
    let res = DB.read "select * from transactions order by id desc limit 1" in
    let arr = List.to_array @@ List.tl_exn (List.concat res) in
    { usd_bal = Float.of_string @@ Array.get arr 0
    ; btc_bal = Float.of_string @@ Array.get arr 1
    ; usd_amount = Float.of_string @@ Array.get arr 2
    ; btc_amount = Float.of_string @@ Array.get arr 3
    ; transaction_type = Array.get arr 4
    }
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
  ;;

  let preprocess_real_price (data : string) : float =
    let json = Yojson.Basic.from_string data in
    [ json ]
    |> Yojson.Basic.Util.filter_member "price"
    |> List.hd_exn
    |> Yojson.Basic.Util.to_string
    |> Float.of_string
  ;;

  let get_real_price () : float =
    Lwt_main.run @@ get "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT"
    |> preprocess_real_price
  ;;

  let buy (btc : float) : res = failwith ""

  let buy_real ~(btc : float) ~(real_price : float) : res =
    let n = btc *. real_price in
    let { usd_bal = prev_usd_bal
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
      ; message = "Not enough dollars in wallet!"
      }
    else (
      let usd_bal, btc_bal = prev_usd_bal -. n, prev_btc_bal +. btc in
      set_latest
        ~usd_bal
        ~btc_bal
        ~btc_amount:btc
        ~usd_amount:n
        ~transaction_type:"BUY_REAL";
      { usd_bal; btc_bal; message = Printf.sprintf "You bought %f Bitcoin at $%f" btc n })
  ;;

  let sell (btc : float) : res = failwith ""

  let sell_real ~(btc : float) ~(real_price : float) : res =
    let n = btc *. real_price in
    let { usd_bal = prev_usd_bal
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
      ; message = "Not enough Bitcoin in wallet!"
      }
    else (
      let usd_bal, btc_bal = prev_usd_bal +. n, prev_btc_bal -. btc in
      set_latest
        ~usd_bal
        ~btc_bal
        ~btc_amount:btc
        ~usd_amount:n
        ~transaction_type:"SELL_REAL";
      { usd_bal; btc_bal; message = Printf.sprintf "You sold %f Bitcoin at $%f" btc n })
  ;;

  let convert (btc : float) : float = failwith ""
  let convert_real ~(btc : float) ~(real_price : float) : float = btc *. real_price
end
