open Utils

exception FailedRequest(string)

@react.component
let make = () => {
  let (list: array<Types.transaction>, setList) = React.useState(_ => [])

  React.useEffect0(() => {
    open Promise
    let _ =
      History.get("http://localhost:8080/history")
      ->then(ret => {
        switch ret {
        | Ok(hist) => setList(_ => hist)->resolve
        | Error(msg) => reject(FailedRequest("Error: " ++ msg))
        }
      })
      ->catch(e => {
        switch e {
        | FailedRequest(msg) => Js.log("Operation failed! " ++ msg)
        | _ => Js.log("Unknown error")
        }
        resolve()
      })
    None
  })

  <div className="w-screen h-screen flex flex-row justify-center">
    <div className="w-frame h-full bg-white"> <Header /> <Content list /> </div>
  </div>
}
