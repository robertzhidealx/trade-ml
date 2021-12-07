open Core
open OUnit2
open Lib

(*
  Most DB and Game functions interact with the database or make requests, thus are not tested.
  Testable utility functions are tested here.
*)

let test_preprocess_real_price _ =
  assert_equal 49151.6
  @@ Game.preprocess_real_price
       "{\n    \"symbol\": \"BTCUSDT\",\n    \"price\": \"49151.60000000\"\n    }";
  assert_equal 50000. @@ Game.preprocess_real_price "{\"price\": \"50000.00000000\"}"
;;

let test_convert _ =
  assert_equal 4925.12 @@ Game.convert ~btc:0.1 ~price:49251.2;
  assert_equal 7880.192 @@ Game.convert ~btc:0.16 ~price:49251.2
;;

let game_tests =
  "Game Tests"
  >: test_list
       [ "Preprocess real price" >:: test_preprocess_real_price
       ; "Convert" >:: test_convert
       ]
;;

let test_preprocess_candlesticks _ =
  assert_equal [| [| 1.; 5.; 7.; 8.; 9.; 10. |] |]
  @@ preprocess_candlesticks
       "[[\"0.0\",\"1.0\",\"2.0\",\"3.0\",\"4.0\",\"5.0\",\"6.0\",\"7.0\",\"8.0\",\"9.0\",\"10.0\",\"11.0\"]]";
  assert_equal [| [| 1.; 5.; 7.; 8.; 9.; 10. |] |]
  @@ preprocess_candlesticks
       "[[0.0,1.0,\"2.0\",\"3.0\",\"4.0\",\"5.0\",\"6.0\",\"7.0\",\"8.0\",\"9.0\",\"10.0\",\"11.0\"]]"
;;

let data_shaping_tests =
  "Data Shaping Tests"
  >: test_list [ "Preprocess candlesticks" >:: test_preprocess_candlesticks ]
;;

(*
  The following test is left out for now as ocaml-torch somehow modifies environment variables,
  causing this test to always fail.
*)

(* let test_inference _ =
  let x =
    [| [| -0.6530; -0.8695; -0.8752; -0.8775; -0.8064; -0.8080 |]
     ; [| -0.6655; -0.9434; -0.9458; -0.9373; -0.8990; -0.9000 |]
     ; [| -0.6329; -0.9054; -0.9092; -0.9209; -0.8544; -0.8552 |]
     ; [| -0.6040; -0.8947; -0.8988; -0.8899; -0.8686; -0.8692 |]
     ; [| -0.5764; -0.9216; -0.9246; -0.9241; -0.9107; -0.9113 |]
     ; [| -0.6154; -0.9469; -0.9489; -0.9562; -0.9279; -0.9285 |]
     ; [| -0.6084; -0.9501; -0.9521; -0.9472; -0.9439; -0.9445 |]
     ; [| -0.6210; -0.9603; -0.9619; -0.9553; -0.9369; -0.9375 |]
     ; [| -0.6063; -0.9588; -0.9605; -0.9533; -0.9469; -0.9475 |]
     ; [| -0.6380; -0.9817; -0.9824; -0.9644; -0.9658; -0.9664 |]
     ; [| -0.6276; -0.9639; -0.9653; -0.9632; -0.9298; -0.9305 |]
     ; [| -0.6096; -0.9474; -0.9495; -0.9643; -0.9203; -0.9210 |]
    |]
  in
  assert_equal (-0.61168676614761353) @@ Forecast.predict x
;;

let forecast_tests = "Inference Tests" >: test_list [ "inference" >:: test_inference ] *)

let series = "Lib Tests" >::: [ game_tests; data_shaping_tests ]
let () = run_test_tt_main series
