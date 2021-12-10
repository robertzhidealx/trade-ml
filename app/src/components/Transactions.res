open Belt

@react.component
let make = (~list: array<Types.transaction>) => {
  <>
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
    <div id="t-list" className="w-full px-6 pt-2 overflow-y-auto">
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
  </>
}