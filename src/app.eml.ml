[@@@warning "-27"]

open! Lib
open! Core

(* let () = get_features () *)

let wallet_page (usd_bal : string) (btc_bal : string) (message : string) =
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bitcoin Trading Game</title>
  </head>
  <body>
    <div>USD balance: <%s usd_bal%></div>
    <div>BTC balance: <%s btc_bal%></div>
    <div><%s message%></div>
  </body>
  </html>

let real_price = ref 0.

let update_real_price
    (inner_handler : Dream.request -> 'a Lwt.t)
    (request : Dream.request)
  =
  let%lwt price_res = get "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT" in
  let price = Game.preprocess_real_price price_res in
  real_price := price;
  inner_handler request
;;

let () =
  Dream.run
  @@ Dream.logger
  @@ update_real_price
  @@ Dream.router
       [ Dream.get "/" (fun _ -> Dream.html "Welcome to the Bitcoin Trading Game")
       ; Dream.get "/init" (fun _ ->
             Game.init ();
             match Game.get_latest () with
             | { usd_bal; btc_bal; usd_amount = _; btc_amount = _; transaction_type = _ }
               ->
               Dream.html
               @@ wallet_page (Float.to_string usd_bal) (Float.to_string btc_bal) "")
       ; Dream.get "/buy_real" (fun req ->
             match Dream.query "btc" req with
             | None -> Dream.html "Missing number of Bitcoin you wish to purchase!"
             | Some res ->
               let btc = Float.of_string res in
               (match Game.buy_real ~btc ~real_price:!real_price with
               | { usd_bal; btc_bal; message } ->
                 Dream.html
                 @@ wallet_page (Float.to_string usd_bal) (Float.to_string btc_bal) message))
       ; Dream.get "/sell_real" (fun req ->
             match Dream.query "btc" req with
             | None -> Dream.html "Missing number of Bitcoin you wish to sell!"
             | Some res ->
               let btc = Float.of_string res in
               (match Game.sell_real ~btc ~real_price:!real_price with
               | { usd_bal; btc_bal; message } ->
                 Dream.html
                 @@ wallet_page (Float.to_string usd_bal) (Float.to_string btc_bal) message))
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
