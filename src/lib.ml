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
      "create table transactions (id serial primary key, balance text, btc text)"
    |> ignore
  ;;

  let delete_table () : unit =
    conn#exec ~expect:[ Command_ok ] "drop table if exists transactions cascade" |> ignore
  ;;

  let write ~(balance : float) ~(btc : float) : unit =
    conn#exec
      ~expect:[ Command_ok ]
      ~params:[| Float.to_string balance; Float.to_string btc |]
      "insert into transactions (balance, btc) values ($1, $2)"
    |> ignore
  ;;

  let read (query : string) : string list list =
    let result = conn#exec ~expect:[ Tuples_ok ] ~binary_result:true query in
    result#get_all_lst
  ;;
end

module Game = struct
  let get_balance () : float * float =
    let res = DB.read "select * from transactions order by id desc limit 1" in
    let pair = List.tl_exn (List.concat res) in
    Float.of_string @@ List.nth_exn pair 0, Float.of_string @@ List.nth_exn pair 1
  ;;

  let set_balance (balance : float) (btc : float) : unit = DB.write ~balance ~btc

  let init () : unit =
    DB.delete_table ();
    DB.create_table ();
    DB.write ~balance:10000. ~btc:0.
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

  let buy (btc : float) : float * float * string = failwith ""

  let buy_real ~(btc : float) ~(real_price : float) : float * float * string =
    let amount, (balance, num_coins) = Float.( * ) btc real_price, get_balance () in
    if Float.( < ) balance amount
    then balance, num_coins, "Not enough dollars in wallet."
    else (
      let new_balance, new_n = Float.( - ) balance amount, Float.( + ) num_coins btc in
      set_balance new_balance new_n;
      ( new_balance
      , new_n
      , "You bought "
        ^ Float.to_string btc
        ^ " Bitcoin at $"
        ^ Float.to_string amount
        ^ "!" ))
  ;;

  let sell (btc : float) : float * float * string = failwith ""

  let sell_real ~(btc : float) ~(real_price : float) : float * float * string =
    let amount, (balance, num_coins) = Float.( * ) btc real_price, get_balance () in
    if Float.( < ) num_coins btc
    then balance, num_coins, "Not enough Bitcoin in wallet."
    else (
      let new_balance, new_n = Float.( + ) balance amount, Float.( - ) num_coins btc in
      set_balance new_balance new_n;
      ( new_balance
      , new_n
      , "You sold " ^ Float.to_string btc ^ " Bitcoin at $" ^ Float.to_string amount ^ "!"
      ))
  ;;

  let convert (btc : float) : float = failwith ""

  let convert_real ~(btc : float) ~(real_price : float) : float =
    Float.( * ) btc real_price
  ;;
end


module Forecast = struct
  let predict (input : float array array) = 
    let input_tensor = Tensor.of_float2 input in 
    let model = Module.load "../forecasting/model/model.pt" in
    Module.forward model [ input_tensor ]
    |> Tensor.to_float0_exn
end
