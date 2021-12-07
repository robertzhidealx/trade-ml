open Utils

exception FailedRequest(string)

@react.component
let make = () => {
  let (usdBal, setUsdBal) = React.useState(_ => 0.)
  let (btcBal, setBtcBal) = React.useState(_ => 0.)
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
      {Header.make()} {Content.make(~usdBal, ~btcBal, ~msg)}
    </div>
  </div>
}
