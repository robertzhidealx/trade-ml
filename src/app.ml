open Lib

let () =
  let str = get_btc_price ~symbol:"BTCUSDT" ~interval:"5m" ~start_time:1635724800000 in
  print_endline str;
  save_csv str @@ Sys.getcwd () ^ "/BTCUSDT-5m-5klines.csv"
;;
