open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix

(* Sample logic to retrieve bitcoin historical data *)
let body =
  Client.get
    (Uri.of_string "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=5m")
  >>= fun (res, body) ->
  let code = res |> Response.status |> Code.code_of_status in
  Printf.printf "Response code: %d\n" code;
  Printf.printf "Headers: %s\n" (res |> Response.headers |> Header.to_string);
  body |> Cohttp_lwt.Body.to_string >|= fun body -> body
;;

let () =
  let body = Lwt_main.run body in
  print_endline ("Received body\n" ^ body)
;;
