(* 
  This file contains specifications to our project, which is separated into
  five parts: database, game, data retrieval, forecasting model, and visualization.
*)

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
    transaction_time:int64 ->
    transaction_type:string ->
    unit

  (* Read the last row of the TRANSACTIONS table *)
  val read : string -> string list list
end

(* Type of response to be sent via Dream *)
type 'data response =
  { data : 'data
  ; code : int
  }

(*
  Logic related to the Bitcoin trading game
*)
module Game : sig
  type transaction =
    { id: int
    ; usd_bal : float
    ; btc_bal : float
    ; usd_amount : float
    ; btc_amount : float
    ; transaction_time : int64
    ; transaction_type : string
    }

  type transaction_list = transaction list

  type wallet = {
    usd_bal: float;
    btc_bal: float;
    msg: string;
  }

  (* Get latest transaction *)
  val get_latest : unit -> transaction

  (* Convert latest transaction to json string format *)
  val get_latest_to_response : transaction -> string

  (*
    Set the latest (dollar balance, number of Bitcoin) pair in the wallet. 
    Under the hood, it appends a row to the bottom of TRANSACTIONS table.
  *)
  val set_latest :
    usd_bal:float ->
    btc_bal:float ->
    usd_amount:float ->
    btc_amount:float ->
    transaction_time:int64 ->
    transaction_type:string ->
    unit

  (*
    Initializes game by recreating a fresh TRANSACTIONS table with
    (dollar balance, number of Bitcoin) being initialized to
    (10000.0, 0).
  *)
  val init : transaction_time:int64 -> unit

  (* Helper to shape real-time Bitcoin spot price into float *)
  val preprocess_real_price : string -> float

  (* Get the latest Bitcoin price in real time *)
  val get_real_price : unit -> string Lwt.t

  (* Buys some amount of bitcoin, via either predicted or real bitcoin price *)
  val buy : btc:float -> price:float -> transaction_time:int64 -> string

  (* Sells some amount of bitcoin, via either predicted or real bitcoin price *)
  val sell: btc:float -> price:float -> transaction_time:int64 -> string

  (*
    Checks the current dollar value of some amount of bitcoin using either
    predicted or real bitcoin price
  *)
  val convert: btc:float -> price:float -> float

  (* Get all transactions. *)
  val get_history: unit -> string
end

(*
  Logic related to forecasting Bitcoin price
*)
module Forecast : sig
  (* Scale an data point to -1 and 1 range *)
  val normalize : float array array -> (float array array)

  (* Descale a single value from [-1, 1] to the normal value *)
  val denormalize : float -> float

  (* Use our trained model to forecast the BTC-USDT price for the next time tick *)
  val predict : float array array -> float
end

(* Data retrieval *)

(* General purpose GET request *)
val get : string -> string Lwt.t

(* Make a GET request to retrieve Bitcoin candlesticks data *)
val get_candlesticks : 
  symbol:string ->
  interval:string ->
  start_time:int ->
  end_time:int ->
  string Lwt.t

(*
  Helper to preprocess and shape response body of kline/candlestick Bitcoin data for predicting
  Bitcoin price at next tick (5 minutes into the future)
*)
val preprocess_candlesticks : string -> float array array

(* Helper to preprocess and shape response body of kline/candlestick Bitcoin data for csv output *)
val preprocess_csv : title:string -> header:string -> body_list:string list -> string

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
  Logic related to visualizing trends in past transactions
*)
module Visualization : sig
  (* grab the recent data for plotting, returns a string of json packed data *)
  val grab_data : unit -> string
end 