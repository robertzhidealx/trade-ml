open Core
open Lwt
open Cohttp_lwt_unix

(* Sample logic to retrieve bitcoin historical data *)
let get =
  Client.get
    (Uri.of_string
       "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m&startTime=1609528409000&endTime=1611256409000")
  >>= fun (_res, body) -> body |> Cohttp_lwt.Body.to_string
;;

let preprocess (data : string) : string list list =
  let trimmed = String.drop_suffix (String.drop_prefix data 1) 1 in
  let records = String.split ~on:']' trimmed in
  List.mapi records ~f:(fun i record ->
      (* print_endline record; *)
      let s = String.drop_prefix record 2 in
      Int.to_string i :: String.split ~on:',' s)
;;

let aggr (json : string list list) : string =
  "BTCUSD-1m-21d\n\
   id,open time,open,high,low,close,volume,close time,quote asset volume,number of \
   trades,taker buy base asset volume,taker buy quote asset volume,ignore\n"
  ^ String.concat
      (List.drop_last_exn
         (List.mapi json ~f:(fun i record ->
              let s = String.concat record ~sep:"," in
              if i <> List.length json - 1 then s ^ "\n" else s)))
      ~sep:""
;;

(* let preprocess (_data : string) : string =
  Yojson.Basic.to_string @@ `List [ `List [ `String "hi"; `String "world" ] ]
;; *)

let from_csv () = Csv.print @@ Csv.load "/Users/robertzhang/Downloads/BTCUSD-1m-21d.csv"

let embedded_csv =
  "\"Banner clickins\"\n\
   \"Clickin\",\"Number\",\"Percentage\",\n\
   \"brand.adwords\",\"4,878\",\"14.4\"\n\
   \"vacation.advert2.adwords\",\"4,454\",\"13.1\"\n\
   \"affiliates.generic.tc1\",\"1,608\",\"4.7\"\n\
   \"brand.overture\",\"1,576\",\"4.6\"\n\
   \"vacation.cheap.adwords\",\"1,515\",\"4.5\"\n\
   \"affiliates.generic.vacation.biggestchoice\",\"1,072\",\"3.2\"\n\
   \"breaks.no-destination.adwords\",\"1,015\",\"3.0\"\n\
   \"fly.no-destination.flightshome.adwords\",\"833\",\"2.5\"\n\
   \"exchange.adwords\",\"728\",\"2.1\"\n\
   \"holidays.cyprus.cheap\",\"574\",\"1.7\"\n\
   \"travel.adwords\",\"416\",\"1.2\"\n\
   \"affiliates.vacation.generic.onlinediscount.200\",\"406\",\"1.2\"\n\
   \"promo.home.topX.ACE.189\",\"373\",\"1.1\"\n\
   \"homepage.hp_tx1b_20050126\",\"369\",\"1.1\"\n\
   \"travel.agents.adwords\",\"358\",\"1.1\"\n\
   \"promo.home.topX.SSH.366\",\"310\",\"0.9\""
;;

let () =
  let body = Lwt_main.run get in
  let str = aggr @@ preprocess body in
  print_endline str;
  let ecsv = Csv.input_all @@ Csv.of_string str in
  Csv.save "/Users/robertzhang/Downloads/test1.csv" ecsv
;;
