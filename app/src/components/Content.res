let make = (~usdBal: float, ~btcBal: float, ~msg: string) => {
  <div className="bg-gray-100 w-full h-content p-12">
    <div className="w-full h-full flex flex-row justify-between">
      <div
        className="w-currency_box_w h-currency_box_h flex flex-col justify-center items-center border-2 border-black">
        <div> {React.string("USD Balance")} </div> <div> {React.float(usdBal)} </div>
      </div>
      <div
        className="w-currency_box_w h-currency_box_h flex flex-col justify-center items-center border-2 border-black">
        <div> {React.string("BTC Balance")} </div> <div> {React.float(btcBal)} </div>
      </div>
    </div>
    <div className=""> {React.string(msg)} </div>
  </div>
}
