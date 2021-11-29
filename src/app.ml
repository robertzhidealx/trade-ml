open! Lib
open! Core

(* let () = get_features () *)

let () =
  (* Game.init (); *)
  match Game.buy_real 0.01 with
  | balance, btc, res ->
    print_endline @@ Float.to_string balance ^ " " ^ Float.to_string btc ^ "\n" ^ res
;;
