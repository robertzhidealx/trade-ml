[@@@warning "-27"]

open Lib
open Core

(* let () = get_features () *)

type 'data response =
  { data : 'data
  ; code : int
  }
[@@deriving yojson]

type wallet_response =
  { usd_bal : float
  ; btc_bal : float
  ; msg : string
  }
[@@deriving yojson]

type error_response =
  { msg : string
  ; code : int
  }
[@@deriving yojson]

type conversion_response =
  { btc : float
  ; usd_value : float
  }
[@@deriving yojson]

type transaction =
  { id : int
  ; usd_bal : float
  ; btc_bal : float
  ; usd_amount : float
  ; btc_amount : float
  ; transaction_time : int
  ; transaction_type : string
  }
[@@deriving yojson]

type t_list = transaction list [@@deriving yojson]

(* Get all transactions. *)
let get_history () : t_list =
  let res = DB.read "select * from transactions" in
  List.fold res ~init:[] ~f:(fun acc row ->
      match row with
      | [ id; usd_bal; btc_bal; usd_amount; btc_amount; time; transaction_type ] ->
        { id = Int.of_string id
        ; usd_bal = Float.of_string usd_bal
        ; btc_bal = Float.of_string btc_bal
        ; usd_amount = Float.of_string usd_amount
        ; btc_amount = Float.of_string btc_amount
        ; transaction_time = Int.of_string time
        ; transaction_type
        }
        :: acc
      | _ -> acc)
;;

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
let predicted_price = ref 0.

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

(* Welcome page *)
let welcome : Dream.route =
  Dream.get "/" (fun request -> Dream.html "Bitcoin Trading Game API")
;;

(* Get all historical transactions *)
let history : Dream.route =
  Dream.get "/history" (fun _ ->
      let hist = get_history () in
      Dream.json
        ~status:(Dream.int_to_status 200)
        ~headers:[ "Access-Control-Allow-Origin", "*" ]
        (Yojson.Safe.to_string
        @@ response_to_yojson
             (fun data -> t_list_to_yojson data)
             { data = hist; code = 200 }))
;;

(* Get past transcations for visulazation *)
let visualize : Dream.route =
  Dream.get "/visualize" (fun _ ->
      let vis = Visualization.grab_data () in
      Dream.json
        ~status:(Dream.int_to_status 200)
        ~headers:[ "Access-Control-Allow-Origin", "*" ]
        vis)
;;

(* Get current wallet information *)
let wallet : Dream.route =
  Dream.get "/wallet" (fun _ ->
      match Game.get_latest () with
      | { id
        ; usd_bal
        ; btc_bal
        ; usd_amount = _
        ; btc_amount = _
        ; transaction_time = _
        ; transaction_type = _
        } ->
        let wallet = { usd_bal; btc_bal; msg = "Query successful!" } in
        Dream.json
          ~status:(Dream.int_to_status 200)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ response_to_yojson
               (fun data -> wallet_response_to_yojson data)
               { data = wallet; code = 200 }))
;;

(* Initialize game *)
let init : Dream.route =
  Dream.get "/init" (fun req ->
      match Dream.query "time" req with
      | None ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] ""
      | Some timestamp ->
        Game.init ~transaction_time:(Int64.of_string timestamp);
        (match Game.get_latest () with
        | { id
          ; usd_bal
          ; btc_bal
          ; usd_amount = _
          ; btc_amount = _
          ; transaction_time = _
          ; transaction_type = _
          } ->
          let wallet = { usd_bal; btc_bal; msg = "Initialized game!" } in
          Dream.json
            ~status:(Dream.int_to_status 200)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ response_to_yojson
                 (fun data -> wallet_response_to_yojson data)
                 { data = wallet; code = 200 })))
;;

(* Buy some number of Bitcoin *)
let buy : Dream.route =
  Dream.get "/buy" (fun req ->
      match Dream.all_queries req with
      | [ (_, n); (_, time) ] ->
        let btc, timestamp = Float.of_string n, Int64.of_string time in
        (match Game.buy ~btc ~price:!real_price ~transaction_time:timestamp with
        | { usd_bal; btc_bal; msg } ->
          let wallet = { usd_bal; btc_bal; msg } in
          Dream.json
            ~status:(Dream.int_to_status 200)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ response_to_yojson
                 (fun data -> wallet_response_to_yojson data)
                 { data = wallet; code = 200 }))
      | _ ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] "")
;;

(* Sell some number of Bitcoin *)
let sell : Dream.route =
  Dream.get "/sell" (fun req ->
      match Dream.all_queries req with
      | [ (_, n); (_, time) ] ->
        let btc, timestamp = Float.of_string n, Int64.of_string time in
        (match Game.sell ~btc ~price:!real_price ~transaction_time:timestamp with
        | { usd_bal; btc_bal; msg } ->
          let wallet = { usd_bal; btc_bal; msg } in
          Dream.json
            ~status:(Dream.int_to_status 200)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ response_to_yojson
                 (fun data -> wallet_response_to_yojson data)
                 { data = wallet; code = 200 }))
      | _ ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] "")
;;

(* Convert some number of Bitcoin into USD using the predicted Bitcoin price *)
let convert : Dream.route =
  Dream.get "/convert" (fun req ->
      match Dream.query "btc" req with
      | None ->
        Dream.json ~status:`Bad_Request ~headers:[ "Access-Control-Allow-Origin", "*" ] ""
      | Some res ->
        let btc = Float.of_string res in
        let value = Game.convert ~btc ~price:!predicted_price in
        let conversion = { btc; usd_value = value } in
        Dream.json
          ~status:(Dream.int_to_status 200)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ response_to_yojson
               (fun data -> conversion_response_to_yojson data)
               { data = conversion; code = 200 }))
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
  @@ Dream.router
       [ welcome
       ; Dream.get "/del" (fun _ ->
             DB.delete_table ();
             Dream.html "")
       ; history
       ; wallet
       ; init
       ; buy
       ; sell
       ; convert
       ; visualize
       ]
  @@ Dream.not_found
;;
