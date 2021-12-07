open Utils

exception FailedRequest(string)

@react.component
let make = () => {
  let (usdBal, setUsdBal) = React.useState(_ => 0)
  let (btcBal, setBtcBal) = React.useState(_ => 0)
  let (msg, setMsg) = React.useState(_ => "")

  React.useEffect0(() => {
    open Promise
    let _ = WalletGet.get("http://localhost:8080/wallet")->then(ret => {
      switch ret {
      | Ok(usd_bal, btc_bal, msg) =>
        setUsdBal(_ => usd_bal)
        setBtcBal(_ => btc_bal)
        setMsg(_ => msg)->resolve
      | Error(msg) => reject(FailedRequest("Error: " ++ msg))
      }
    })
    None
  })

  <div className="w-screen h-screen flex flex-row justify-center">
    <div className="w-frame h-full bg-white">
      <div className="w-full  h-14 flex flex-row justify-between p-4">
        <div className="flex flex-row items-center font-serif text-xl font-medium">
          {React.string("TradeML")}
        </div>
        <a href="https://github.com/robertzhidealx/btc-game-monorepo">
          <img className="flex flex-row items-center" src="/img/github.svg" />
        </a>
      </div>
      <div className="bg-gray-100 w-full h-content">
        <p className=""> {React.array([React.string("USD Balance: "), React.int(usdBal)])} </p>
        <p className=""> {React.array([React.string("BTC Balance: "), React.int(btcBal)])} </p>
        <p className=""> {React.string(msg)} </p>
      </div>
    </div>
  </div>
}
