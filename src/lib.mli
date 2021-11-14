(* 
  This is file contains specifications to our project, which is separated into
  three parts: data retrieval, model, and visualization.
*)

(* Data retrieval *)

(*
  A tuple representing one unit of data of some symbol (bitcoin), including its high and low prices,
  volume, etc.

  Format:

  (
    1499040000000,      // Open time
    "0.01634790",       // Open
    "0.80000000",       // High
    "0.01575800",       // Low
    "0.01577100",       // Close
    "148976.11427815",  // Volume
    1499644799999,      // Close time
    "2434.19055334",    // Quote asset volume
    308,                // Number of trades
    "1756.87402397",    // Taker buy base asset volume
    "28.46694368",      // Taker buy quote asset volume
    "17928899.62484339" // Ignore.
  )
*)
type datum

(*
Function to obtain historical symbol (bitcoin) data at the specified interval (minimum one minute),
including the symbol's high and low prices, volume, etc., to be used as features trained in the
LSTM model.

Under the hood, it calls the API endpoint at
https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#klinecandlestick-data.

Example usage: get_historical_data ~symbol:"BTCUSD" ~interval:"1m" ~start_time:1636573390 ~end_time:1636918990

Response format:

[
  (
    1499040000000,      // Open time
    "0.01634790",       // Open
    "0.80000000",       // High
    "0.01575800",       // Low
    "0.01577100",       // Close
    "148976.11427815",  // Volume
    1499644799999,      // Close time
    "2434.19055334",    // Quote asset volume
    308,                // Number of trades
    "1756.87402397",    // Taker buy base asset volume
    "28.46694368",      // Taker buy quote asset volume
    "17928899.62484339" // Ignore.
  );
  ...
]

*)
val get_historical_data : symbol:string -> interval:string -> start_time:int -> end_time: int -> datum list

(*
Function to extract a specific feature (field) from a list of retrieved historical bitcoin data.

Example usage: get_feature data ~feature:1 (where 1 refers to the feature at index 1 of the datum type)
*)
val get_feature : datum list -> feature:int -> 'a list

(* Model *)

(* Prediction using trained model *)
type prediction

(* Visualization *)

type graph (* Graph from Owl *)
type plot_settings (* Settings to be passed into Owl*)

(* Plot the prediction *)
val plot : prediction -> plot_settings -> graph