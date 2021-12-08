open Types

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

module History = {
  type res = response<array<transaction>>

  @val
  external fetch: (string, ~params: 'params=?, unit) => Promise.t<Response.t<res>> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, ())
    ->then(res => Response.json(res))
    ->then(data =>
      switch data.code {
      | 200 => Ok(data.data)
      | _ => Error("Internal Server Error")
      }->resolve
    )
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

// module WalletResponse: ResType = {
//   type data = {"usd_bal": float, "btc_bal": float, "msg": string}
//   type t<'data>
//   type tt = t<data>
//   @send external json: tt => Promise.t<'data> = "json"
// }
