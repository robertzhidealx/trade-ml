open Utils

module WalletGet = MakeGet(WalletResponse)

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

  <div>
    <div className="bg-blue-200 w-screen h-16">
      <p className=""> {React.array([React.string("USD Balance: "), React.int(usdBal)])} </p>
      <p className=""> {React.array([React.string("BTC Balance: "), React.int(btcBal)])} </p>
      <p className=""> {React.string(msg)} </p>
    </div>
  </div>
}
