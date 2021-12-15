[@@@warning "-27"]

open Lib
open Core

(* let () = get_features () *)

type error_response =
  { msg : string
  ; code : int
  }
[@@deriving yojson]

type conversion_response =
  { btc : float
  ; real_usd_value : float
  ; predicted_usd_value : float
  }
[@@deriving yojson]

let real_price = ref 0.

(* Update real Bitcoin price before every request *)
let update_real_price
    (inner_handler : Dream.request -> 'a Lwt.t)
    (request : Dream.request)
  =
  let%lwt price_res = Game.get_real_price () in
  let price = Game.preprocess_real_price price_res in
  real_price := price;
  inner_handler request
;;

(* Update predicted Bitcoin price before every request *)
let predicted_price = ref 12.121213213121

let update_predicted_price
    (inner_handler : Dream.request -> 'a Lwt.t)
    (request : Dream.request)
  =
  let now = Float.to_int @@ (Unix.time () *. 1000.) in
  let%lwt price_res =
    get_candlesticks
      ~symbol:"BTCUSDT"
      ~interval:"5m"
      ~start_time:(now - 3600000)
      ~end_time:now
  in
  (* print_endline price_res; *)
  let ticks = preprocess_candlesticks price_res in
  (* ignore ticks; *)
  predicted_price := Forecast.predict ticks;
  inner_handler request
;;

(*
  Welcome page.
  localhost:8080/
*)
let welcome : Dream.route =
  Dream.get "/" (fun request -> Dream.html "Bitcoin Trading Game API")
;;

(*
  Get all historical transactions.
  e.g., localhost:8080/history
*)
let history : Dream.route =
  Dream.get "/history" (fun _ ->
      let hist = Game.get_history () in
      Dream.json
        ~status:(Dream.int_to_status 200)
        ~headers:[ "Access-Control-Allow-Origin", "*" ]
        hist)
;;

(*
  Get current wallet information.
  e.g., localhost:8080/wallet
*)
let wallet : Dream.route =
  Dream.get "/wallet" (fun _ ->
      let res = Game.get_latest () in
      Dream.json
        ~status:(Dream.int_to_status 200)
        ~headers:[ "Access-Control-Allow-Origin", "*" ]
        (Game.get_latest_to_response res))
;;

(*
  Initialize game.
  e.g., localhost:8080/init?time=1639543509465
*)
let init : Dream.route =
  Dream.get "/init" (fun req ->
      match Dream.query "time" req with
      | None ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] ""
      | Some timestamp ->
        Game.init ~transaction_time:(Int64.of_string timestamp);
        Dream.json
          ~status:(Dream.int_to_status 200)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ response_to_yojson
               (fun x -> Yojson.Safe.from_string x)
               { data = "Initialized game!"; code = 200 }))
;;

(*
  Buy some number of Bitcoin.
  e.g., localhost:8080/buy?btc=0.01&time=1639543509465
*)
let buy : Dream.route =
  Dream.get "/buy" (fun req ->
      match Dream.all_queries req with
      | [ ("btc", n); ("time", time) ] ->
        let btc, timestamp = Float.of_string n, Int64.of_string time in
        Game.buy ~btc ~price:!real_price ~transaction_time:timestamp
        |> Dream.json
             ~status:(Dream.int_to_status 200)
             ~headers:[ "Access-Control-Allow-Origin", "*" ]
      | _ ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] "")
;;

(*
  Sell some number of Bitcoin.
  e.g., localhost:8080/sell?btc=0.01&time=1639543509465
*)
let sell : Dream.route =
  Dream.get "/sell" (fun req ->
      match Dream.all_queries req with
      | [ ("btc", n); ("time", time) ] ->
        let btc, timestamp = Float.of_string n, Int64.of_string time in
        Game.sell ~btc ~price:!real_price ~transaction_time:timestamp
        |> Dream.json
             ~status:(Dream.int_to_status 200)
             ~headers:[ "Access-Control-Allow-Origin", "*" ]
      | _ ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] "")
;;

(*
  Convert some number of Bitcoin into USD using the predicted and real-time Bitcoin price.
  e.g., localhost:8080/convert?btc=0.01
*)
let convert : Dream.route =
  Dream.get "/convert" (fun req ->
      match Dream.query "btc" req with
      | Some res ->
        let btc = Float.of_string res in
        let real = Game.convert ~btc ~price:!real_price in
        let predicted = Game.convert ~btc ~price:!predicted_price in
        let conversion =
          { btc; real_usd_value = real; predicted_usd_value = predicted }
        in
        Dream.json
          ~status:(Dream.int_to_status 200)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ response_to_yojson
               (fun data -> conversion_response_to_yojson data)
               { data = conversion; code = 200 })
      | None ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] "")
;;

(*
  Get past transcations for visulazation.
  e.g., localhost:8080/visualize
*)
let visualize : Dream.route =
  Dream.get "/visualize" (fun _ ->
      let vis = Visualization.grab_data () in
      Dream.json
        ~status:(Dream.int_to_status 200)
        ~headers:[ "Access-Control-Allow-Origin", "*" ]
        vis)
;;

(* Template for catching error statuses and forwarding errors to the client *)
let my_error_template debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status
  and msg = Dream.status_to_string status in
  suggested_response
  |> Dream.with_header "Content-Type" Dream.application_json
  |> Dream.with_header "Access-Control-Allow-Origin" "*"
  |> Dream.with_body @@ Yojson.Safe.to_string @@ error_response_to_yojson { msg; code }
  |> Lwt.return
;;

let () =
  Dream.run ~error_handler:(Dream.error_template my_error_template)
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ update_predicted_price
  @@ update_real_price
  @@ Dream.router [ welcome; history; wallet; init; buy; sell; convert; visualize ]
  @@ Dream.not_found
;;
