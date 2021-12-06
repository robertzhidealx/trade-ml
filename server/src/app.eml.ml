[@@@warning "-27"]

open! Lib
open! Core

(* let () = get_features () *)
let real_price = ref 0.

type wallet_response =
  { usd_bal : float
  ; btc_bal : float
  ; msg : string
  }
[@@deriving yojson]

let update_real_price
    (inner_handler : Dream.request -> 'a Lwt.t)
    (request : Dream.request)
  =
  let%lwt price_res = Game.get_real_price () in
  let price = Game.preprocess_real_price price_res in
  real_price := price;
  inner_handler request
;;

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ update_real_price
  @@ Dream.router
       [ (* Dream.get "/" (fun request -> Dream.html @@ show_form ~message:"" request); *)
         Dream.get "/" (fun request -> Dream.html "Bitcoin Trading Game API")
       ; Dream.get "/wallet" (fun _ ->
             match Game.get_latest () with
             | { usd_bal; btc_bal; usd_amount = _; btc_amount = _; transaction_type = _ }
               ->
               Dream.json
                 ~status:(Dream.int_to_status 200)
                 ~headers:[ "Access-Control-Allow-Origin", "*" ]
                 (Yojson.Safe.to_string
                 @@ wallet_response_to_yojson { usd_bal; btc_bal; msg = "" }))
       ; Dream.get "/init" (fun _ ->
             Game.init ();
             match Game.get_latest () with
             | { usd_bal; btc_bal; usd_amount = _; btc_amount = _; transaction_type = _ }
               -> Dream.html @@ Printf.sprintf "%f, %f" usd_bal btc_bal)
       ; Dream.get "/buy_real" (fun req ->
             match Dream.query "btc" req with
             | None -> Dream.html "Missing number of Bitcoin you wish to purchase!"
             | Some res ->
               let btc = Float.of_string res in
               (match Game.buy_real ~btc ~real_price:!real_price with
               | { usd_bal; btc_bal; message } ->
                 Dream.html @@ Printf.sprintf "%f, %f\n%s" usd_bal btc_bal message))
       ; Dream.get "/sell_real" (fun req ->
             match Dream.query "btc" req with
             | None -> Dream.html "Missing number of Bitcoin you wish to sell!"
             | Some res ->
               let btc = Float.of_string res in
               (match Game.sell_real ~btc ~real_price:!real_price with
               | { usd_bal; btc_bal; message } ->
                 Dream.html @@ Printf.sprintf "%f, %f\n%s" usd_bal btc_bal message))
       ; Dream.get "/convert_real" (fun req ->
             match Dream.query "btc" req with
             | None -> Dream.html "Missing number of Bitcoin you wish to convert!"
             | Some res ->
               let btc = Float.of_string res in
               let value = Game.convert_real ~btc ~real_price:!real_price in
               Dream.html
               @@ Float.to_string btc
               ^ " Bitcoin is currently an equivalent of "
               ^ Float.to_string value
               ^ " USD")
       ]
  @@ Dream.not_found
;;
