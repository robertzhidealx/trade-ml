open Types

exception FailedRequest(string)

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

module General = {
  type res = response<wallet>

  @val
  external fetch: (string, ~params: 'params=?, unit) => Promise.t<Response.t<res>> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, ())
    ->then(res => Response.json(res))
    ->then(data =>
      switch data.code {
      | 200 => Ok(data.data)
      | 500 => Error("Game not started")
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
      | 500 => Error("Game not started")
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
