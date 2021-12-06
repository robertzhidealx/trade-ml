module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

module API = {
  type response = {"code": int}

  @val
  external fetch: (string, ~params: 'params=?, unit) => Promise.t<Response.t<{"code": int}>> =
    "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, ())
    ->then(res => Response.json(res))
    ->then(data => Ok(data["code"])->resolve)
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

exception FailedRequest(string)

@react.component
let make = () => {
  let (code, setCode) = React.useState(_ => 0)
  React.useEffect0(() => {
    let _ = API.get("http://localhost:8080/")->Promise.then(ret => {
      switch ret {
      | Ok(code) => Promise.resolve(setCode(_ => code))
      | Error(msg) => Promise.reject(FailedRequest("Error: " ++ msg))
      }
    })
    None
  })

  <div>
    <div className="bg-blue-200 w-screen h-16"> <p className=""> {React.int(code)} </p> </div>
  </div>
}
