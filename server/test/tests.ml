open! Core
open! OUnit2
open! Lib

(*
  Most DB and Game functions interact with the database or make requests, thus are not tested.
  Testable utility functions are tested here.
*)

let test_preprocess_real_price _ =
  assert_equal 49151.6
  @@ Game.preprocess_real_price
       "{\n    \"symbol\": \"BTCUSDT\",\n    \"price\": \"49151.60000000\"\n    }"
;;

let test_convert _ = assert_equal 4925.12 @@ Game.convert ~btc:0.1 ~price:49251.2

let game_tests =
  "Game Tests"
  >: test_list
       [ "Preprocess real price" >:: test_preprocess_real_price
       ; "Convert" >:: test_convert
       ]
;;

let test_preprocess _ =
  assert_equal [| [| 1.; 5.; 7.; 8.; 9.; 10. |] |]
  @@ preprocess
       "[[\"0.0\",\"1.0\",\"2.0\",\"3.0\",\"4.0\",\"5.0\",\"6.0\",\"7.0\",\"8.0\",\"9.0\",\"10.0\",\"11.0\"]]";
  assert_equal [| [| 1.; 5.; 7.; 8.; 9.; 10. |] |]
  @@ preprocess
       "[[0.0,1.0,\"2.0\",\"3.0\",\"4.0\",\"5.0\",\"6.0\",\"7.0\",\"8.0\",\"9.0\",\"10.0\",\"11.0\"]]"
;;

let data_shaping_tests =
  "Data Shaping Tests" >: test_list [ "Preprocess" >:: test_preprocess ]
;;

let series = "Lib Tests" >::: [ game_tests; data_shaping_tests ]
let () = run_test_tt_main series
