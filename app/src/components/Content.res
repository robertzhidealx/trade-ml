open Belt

@react.component
let make = (~list: array<Types.transaction>) => {
  <div className="bg-frame w-full h-content flex flex-col-reverse pb-2">
    <div className="h-8 mt-2 grid grid-cols-3 gap-x-2 mx-6">
      <button
        className="buy-btn font-serif border-2 border-white bg-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in">
        {React.string("Buy")}
      </button>
      <button
        className="sell-btn font-serif border-2 border-white bg-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in">
        {React.string("Sell")}
      </button>
      <button
        className="convert-btn font-serif border-2 border-white bg-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in">
        {React.string("Convert")}
      </button>
    </div>
    <div className="grid grid-cols-3 mx-6 drop-shadow-md h-6">
      <div className="bg-white text-sm font-bold flex flex-row justify-center items-center">
        {React.string("USD Balance")}
      </div>
      <div className="bg-white text-sm font-bold flex flex-row justify-center items-center">
        {React.string("BTC Balance")}
      </div>
      <div className="bg-white text-sm font-bold flex flex-row justify-center items-center">
        {React.string("Type")}
      </div>
    </div>
    <div className="w-full px-6 pt-2 overflow-y-auto">
      {Array.mapWithIndex(list, (i, tsn) =>
        <div
          className={`grid grid-cols-3 mt-2 ${i == 0 ? "mb-2" : ""} drop-shadow-md h-6`}
          key={Int.toString(tsn.id)}>
          <div className="rounded-l-md bg-white text-sm flex flex-row justify-center items-center">
            {React.float(tsn.usd_bal)}
          </div>
          <div className="text-center bg-white text-sm flex flex-row justify-center items-center">
            {React.float(tsn.btc_bal)}
          </div>
          <div
            className="rounded-r-md text-center bg-white text-sm flex flex-row justify-center items-center">
            {React.string(tsn.transaction_type)}
          </div>
        </div>
      )
      ->Array.reverse
      ->React.array}
    </div>
  </div>
}
