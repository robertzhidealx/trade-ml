(* 
  This file contains specifications to our project, which is separated into
  four parts: game logic, data retrieval, model, and visualization.
*)

(* Game logic *)

(* Module containing game logic *)
module type Game = sig
  type wallet

  (* Initializes game *)
  val init : wallet

  (* Buys some amount of bitcoin, either via predicted rate or real rate (boolean argument real_rate) *)
  val buy : float -> real_rate:bool -> wallet

  (* Sells some amount of bitcoin *)
  val sell : float -> real_rate:bool -> wallet

  (* Checks the current value of some amount of bitcoin in the target currency *)
  val convert : float -> target:string -> real_rate:bool -> float

  (* Checks the profit from selling some amount of bitcoin if sell now *)
  val profit : float -> real_rate:bool -> float

  (* Checks if the user is bankrupt right now *)
  val is_bankrupt : real_rate:bool ->  bool
end

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

(* Output data to csv file *)
val to_csv : string -> unit

(* Model *)

(* Prediction using trained model *)
type prediction

type tensor_t

(*
  Import the trained model from file (in Torch Script format), given the input data tensor,
  predict # of steps data points into the future using the model.
*)
val infer : file:string -> tensor:tensor_t -> steps:int -> prediction

(* Visualization *)

type graph (* Graph from Owl *)
type plot_settings (* Settings to be passed into Owl*)

(* Plot the prediction *)
val plot : prediction -> plot_settings -> graph