open Types

exception FailedRequest(string)

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

let params = {
  "method": "GET",
}

module General = {
  type res = response<wallet>

  @val
  external fetch: (string, 'params) => Promise.t<Response.t<res>> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, params)
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
  external fetch: (string, 'params) => Promise.t<Response.t<res>> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, params)
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

module Prediction = {
  type res = response<prediction>

  @val
  external fetch: (string, 'params) => Promise.t<Response.t<res>> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, params)
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

module Visualization = {
  type res = response<array<visualization>>

  @val
  external fetch: (string, 'params) => Promise.t<Response.t<res>> = "fetch"

  let get = (url: string) => {
    open Promise
    fetch(url, params)
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

let timeToString = (time: int) => {
  open Belt
  let date = Js.Date.fromFloat(Int.toFloat(time))
  let month = date->Js.Date.getMonth
  let day = date->Js.Date.getDate
  let year = date->Js.Date.getFullYear->Float.toString
  let hour = date->Js.Date.getHours
  let minutes = date->Js.Date.getMinutes
  let seconds = date->Js.Date.getSeconds
  `${month < 10. ? "0" ++ Float.toString(month) : Float.toString(month)}-${day < 10.
      ? "0" ++ Float.toString(day)
      : Float.toString(day)}-${year} ${hour < 10.
      ? "0" ++ Float.toString(hour)
      : Float.toString(hour)}:${minutes < 10.
      ? "0" ++ Float.toString(minutes)
      : Float.toString(minutes)}:${seconds < 10.
      ? "0" ++ Float.toString(seconds)
      : Float.toString(seconds)}
        `
}
