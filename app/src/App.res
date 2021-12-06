module type ResType = {
  type t<'data>
  type tt
  @send external json: tt => Promise.t<'data> = "json"
}

module WalletResponse: ResType = {
  type data = {"usd_bal": float, "btc_bal": float, "msg": string}
  type t<'data>
  type tt = t<data>
  @send external json: tt => Promise.t<'data> = "json"
}

module MakeGet = (Res: ResType) => {
  type response = Res.tt

  @val
  external fetch: (string, ~params: 'params=?, unit) => Promise.t<Res.tt> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, ())
    ->then(res => Res.json(res))
    ->then(data => Ok(data["usd_bal"], data["btc_bal"], data["msg"])->resolve)
    ->catch(e => {
      let msg = switch e {
      | JsError(err) =>
        switch Js.Exn.message(err) {
        | Some(msg) => msg
        | None => ""
        }
      | _ => "Unexpected error occurred"
      }
      Error(msg)->resolve
    })
  }
}

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
