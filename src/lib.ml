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

let get_btc_price ~(symbol : string) ~(interval : string) ~(start_time : int) : string =
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

let save_csv (csv : string) (file : string) =
  Csv.input_all @@ Csv.of_string csv |> Csv.save file
;;

let get_features () : unit =
  let str = get_btc_price ~symbol:"BTCUSDT" ~interval:"5m" ~start_time:1635724800000 in
  save_csv str @@ Sys.getcwd () ^ "/BTCUSDT-5m-5klines.csv"
;;

(* let preprocess (_data : string) : string =
  Yojson.Basic.to_string @@ `List [ `List [ `String "hi"; `String "world" ] ]
;; *)

(* Function to load data from a csv file *)
(* let from_csv () = Csv.print @@ Csv.load (Sys.getcwd () ^ "/BTCUSD-1m-21d.csv") *)

(* Game Logic *)

let file : string = "cache.txt"

module Game = struct
  let get_balance () : float * float =
    let ic = In_channel.create file in
    let balance, n = ref 0., ref 0. in
    try
      while true do
        match In_channel.input_line ic with
        | Some s ->
          let pair = String.split s ~on:' ' in
          balance := Float.of_string @@ List.nth_exn pair 0;
          n := Float.of_string @@ List.nth_exn pair 1
        | None -> raise Exit
      done;
      !balance, !n
    with
    | Exit ->
      In_channel.close ic;
      !balance, !n
  ;;

  let set_balance (balance : float) (n : float) : unit =
    let oc = Out_channel.create ~append:true file in
    Printf.fprintf oc "%f %f\n" balance n;
    Out_channel.close oc
  ;;

  let init () : unit =
    if Sys.file_exists_exn file then Sys.remove file;
    let oc = Out_channel.create file in
    Printf.fprintf oc "%f %f\n" 10000. 0.;
    Out_channel.close oc
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

  let buy (n : float) ~(real_rate : bool) : float * float * string =
    match real_rate with
    | true ->
      let amount, (balance, num_coins) =
        Float.( * ) n (get_real_price ()), get_balance ()
      in
      if Float.( < ) balance amount
      then balance, num_coins, "Not enough dollars in wallet."
      else (
        let new_balance, new_n = Float.( - ) balance amount, Float.( + ) num_coins n in
        set_balance new_balance new_n;
        ( new_balance
        , new_n
        , "You bought "
          ^ Float.to_string n
          ^ " Bitcoin at $"
          ^ Float.to_string amount
          ^ "!" ))
    | false -> 0., 0., "unimplemented"
  ;;

  let sell (n : float) ~(real_rate : bool) : float * float * string =
    match real_rate with
    | true ->
      let amount, (balance, num_coins) =
        Float.( * ) n (get_real_price ()), get_balance ()
      in
      if Float.( < ) num_coins n
      then balance, num_coins, "Not enough Bitcoin in wallet."
      else (
        let new_balance, new_n = Float.( + ) balance amount, Float.( - ) num_coins n in
        set_balance new_balance new_n;
        ( new_balance
        , new_n
        , "You sold " ^ Float.to_string n ^ " Bitcoin at $" ^ Float.to_string amount ^ "!"
        ))
    | false -> 0., 0., "unimplemented"
  ;;

  let convert (n : float) ~(target : string) ~(real_rate : bool) : float = failwith ""
  let profit (n : float) ~(real_rate : bool) : float = failwith ""
  let is_bankrupt ~(real_rate : bool) : bool = failwith ""
end
