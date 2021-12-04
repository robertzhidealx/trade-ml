(* 
  This file contains specifications to our project, which is separated into
  four parts: game logic, data retrieval, model, and visualization.
*)

(* Game logic *)

(*
  Logic related to accessing and manipulating the database used to store
  transactions throughout a game.
*)
module DB : sig
  (* A PostgreSQL database connection *)
  val conn : Postgresql.connection

  (* Create the TRANSACTIONS table *)
  val create_table : unit -> unit

  (* Drop the TRANSACTIONS table if exists *)
  val delete_table : unit -> unit

  (* Append a row into the TRANSACTIONS table *)
  val write :
    usd_bal:float ->
    btc_bal:float ->
    usd_amount:float ->
    btc_amount:float ->
    transaction_type:string ->
    unit

  (* Read the last row of the TRANSACTIONS table *)
  val read : string -> string list list
end

(* Module containing game logic *)

(*
  Logic related to the Bitcoin trading game
*)
module Game : sig
  type transaction =
    { usd_bal : float
    ; btc_bal : float
    ; usd_amount : float
    ; btc_amount : float
    ; transaction_type : string
    }

  type res = {
    usd_bal: float;
    btc_bal: float;
    message: string;
  }

  (* Get the current (dollar balance, number of Bitcoin) pair in the wallet. *)
  val get_latest : unit -> transaction

  (*
    Set the latest (dollar balance, number of Bitcoin) pair in the wallet. 
    Under the hood, it appends a row to the bottom of TRANSACTIONS table.
  *)
  val set_latest :
    usd_bal:float ->
    btc_bal:float ->
    usd_amount:float ->
    btc_amount:float ->
    transaction_type:string ->
    unit

  (*
    Initializes game by recreating a fresh TRANSACTIONS table with
    (dollar balance, number of Bitcoin) being initialized to
    (10000.0, 0).
  *)
  val init : unit -> unit

  (* Helper to shape real-time Bitcoin spot price into float *)
  val preprocess_real_price : string -> float

  (* Get the latest Bitcoin price in real time *)
  val get_real_price : unit -> float

  (* Buys some amount of bitcoin, via predicted bitcoin price *)
  val buy : float -> res

  (* Buys some amount of bitcoin, via real bitcoin price *)
  val buy_real : btc:float -> real_price:float -> res

  (* Sells some amount of bitcoin, via predicted bitcoin price *)
  val sell : float -> res

  (* Sells some amount of bitcoin, via real bitcoin price *)
  val sell_real : btc:float -> real_price:float -> res

  (* Checks the current dollar value of some amount of bitcoin using predicted bitcoin price*)
  val convert : float -> float

  (* Checks the current dollar value of some amount of bitcoin using real bitcoin price*)
  val convert_real : btc:float -> real_price:float -> float
end

(* Data retrieval *)

(* General purpose GET request *)
val get : string -> string Lwt.t

(* Helper to preprocess and shape response body of kline/candlestick Bitcoin data *)
val preprocess : title:string -> header:string -> body_list:string list -> string

(*
  Get 5000 lines (approx. 18 days) worth of csv data, of the given `symbol`, at the given `interval`, 
  from the given `start_time`.
*)
val get_btc_data : symbol:string -> interval:string -> start_time:int -> string

(* Save formatted CSV data to specified CSV file *)
val save_csv : csv:string -> file:string -> unit

(*
  Core function to obtain historical Bitcoin data including its high and low prices,
  volume, etc. (full list of features below), to be used as features trained in the LSTM model.

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
*)
val get_features : unit -> unit

(* 
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
val plot : prediction -> plot_settings -> graph *)