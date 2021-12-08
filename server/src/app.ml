[@@@warning "-27"]

open! Lib
open! Core

(* let () = get_features () *)

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
  ; transaction_type : string
  }
[@@deriving yojson]

type t_list = transaction list [@@deriving yojson]

(* Get all transactions. *)
let get_history () : t_list =
  let res = DB.read "select * from transactions" in
  List.fold res ~init:[] ~f:(fun acc row ->
      match row with
      | [ id; usd_bal; btc_bal; usd_amount; btc_amount; transaction_type ] ->
        { id = Int.of_string id
        ; usd_bal = Float.of_string usd_bal
        ; btc_bal = Float.of_string btc_bal
        ; usd_amount = Float.of_string usd_amount
        ; btc_amount = Float.of_string btc_amount
        ; transaction_type
        }
        :: acc
      | _ -> acc)
;;

let real_price = ref 0.

let update_real_price
    (inner_handler : Dream.request -> 'a Lwt.t)
    (request : Dream.request)
  =
  let%lwt price_res = Game.get_real_price () in
  let price = Game.preprocess_real_price price_res in
  real_price := price;
  inner_handler request
;;

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

let welcome : Dream.route =
  Dream.get "/" (fun request -> Dream.html "Bitcoin Trading Game API")
;;

let history : Dream.route =
  Dream.get "/history" (fun _ ->
      try
        let hist = get_history () in
        Dream.json
          ~status:(Dream.int_to_status 200)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string @@ t_list_to_yojson hist)
      with
      | Postgresql.Error e ->
        Dream.respond
          ~status:(Dream.int_to_status 500)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ error_response_to_yojson { msg = "Database error"; code = 500 }))
;;

let wallet : Dream.route =
  Dream.get "/wallet" (fun _ ->
      try
        match Game.get_latest () with
        | { id; usd_bal; btc_bal; usd_amount = _; btc_amount = _; transaction_type = _ }
          ->
          Dream.json
            ~status:(Dream.int_to_status 200)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ wallet_response_to_yojson { usd_bal; btc_bal; msg = "" })
      with
      | Postgresql.Error e ->
        Dream.json
          ~status:(Dream.int_to_status 500)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ error_response_to_yojson { msg = "Database error"; code = 400 }))
;;

let init : Dream.route =
  Dream.get "/init" (fun _ ->
      try
        Game.init ();
        match Game.get_latest () with
        | { id; usd_bal; btc_bal; usd_amount = _; btc_amount = _; transaction_type = _ }
          ->
          Dream.json
            ~status:(Dream.int_to_status 200)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ wallet_response_to_yojson { usd_bal; btc_bal; msg = "Initialized game!" })
      with
      | Postgresql.Error e ->
        Dream.json
          ~status:(Dream.int_to_status 500)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ error_response_to_yojson { msg = "Database error"; code = 400 }))
;;

let buy : Dream.route =
  Dream.get "/buy" (fun req ->
      match Dream.query "btc" req with
      | None ->
        Dream.json
          ~status:(Dream.int_to_status 400)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ error_response_to_yojson
               { msg = "Missing number of Bitcoin you wish to buy!"; code = 400 })
      | Some res ->
        let btc = Float.of_string res in
        (try
           match Game.buy ~btc ~price:!real_price with
           | { usd_bal; btc_bal; msg } ->
             Dream.json
               ~status:(Dream.int_to_status 200)
               ~headers:[ "Access-Control-Allow-Origin", "*" ]
               (Yojson.Safe.to_string
               @@ wallet_response_to_yojson { usd_bal; btc_bal; msg })
         with
        | Postgresql.Error e ->
          Dream.json
            ~status:(Dream.int_to_status 500)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ error_response_to_yojson { msg = "Database error"; code = 400 })))
;;

let sell : Dream.route =
  Dream.get "/sell" (fun req ->
      match Dream.query "btc" req with
      | None ->
        Dream.json
          ~status:(Dream.int_to_status 400)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ wallet_response_to_yojson
               { usd_bal = 0.
               ; btc_bal = 0.
               ; msg = "Missing number of Bitcoin you wish to sell!"
               })
      | Some res ->
        let btc = Float.of_string res in
        (try
           match Game.sell ~btc ~price:!real_price with
           | { usd_bal; btc_bal; msg } ->
             Dream.json
               ~status:(Dream.int_to_status 200)
               ~headers:[ "Access-Control-Allow-Origin", "*" ]
               (Yojson.Safe.to_string
               @@ wallet_response_to_yojson { usd_bal; btc_bal; msg })
         with
        | Postgresql.Error e ->
          Dream.json
            ~status:(Dream.int_to_status 500)
            ~headers:[ "Access-Control-Allow-Origin", "*" ]
            (Yojson.Safe.to_string
            @@ error_response_to_yojson { msg = "Database error"; code = 400 })))
;;

let convert : Dream.route =
  Dream.get "/convert" (fun req ->
      match Dream.query "btc" req with
      | None ->
        Dream.json
          ~status:(Dream.int_to_status 400)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ error_response_to_yojson
               { msg = "Missing number of Bitcoin you wish to convert!"; code = 400 })
      | Some res ->
        let btc = Float.of_string res in
        let value = Game.convert ~btc ~price:!predicted_price in
        Dream.json
          ~status:(Dream.int_to_status 200)
          ~headers:[ "Access-Control-Allow-Origin", "*" ]
          (Yojson.Safe.to_string
          @@ conversion_response_to_yojson { btc; usd_value = value }))
;;

let () =
  Dream.run
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
       ]
  @@ Dream.not_found
;;
