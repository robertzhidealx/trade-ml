open Core
open Lwt
open Cohttp_lwt_unix

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
        let j = Yojson.Basic.Util.filter_list [ json ] in
        let res =
          List.mapi (List.hd_exn j) ~f:(fun i item ->
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

(* let preprocess (_data : string) : string =
  Yojson.Basic.to_string @@ `List [ `List [ `String "hi"; `String "world" ] ]
;; *)

(* Function to load data from a csv file *)
(* let from_csv () = Csv.print @@ Csv.load (Sys.getcwd () ^ "/BTCUSD-1m-21d.csv") *)
