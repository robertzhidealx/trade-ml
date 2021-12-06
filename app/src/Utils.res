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
