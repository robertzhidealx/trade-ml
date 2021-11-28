open Lib

(* let () = get_features () *)

let () =
  (* Game.init (); *)
  match Game.sell 0.1 ~real_rate:true with
  | balance, n, res ->
    print_endline @@ Float.to_string balance ^ " " ^ Float.to_string n ^ "\n" ^ res
;;
