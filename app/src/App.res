open Types
open Utils

@react.component
let make = () => {
  let (list: array<transaction>, setList) = React.useState(_ => [])
  let (loading, setLoading) = React.useState(_ => false)
  let (hasError, setHasError) = React.useState(_ => false)

  React.useEffect2(() => {
    open Promise
    let _ =
      History.get("http://localhost:8080/history")
      ->then(ret => {
        switch ret {
        | Ok(hist) =>
          setHasError(_ => false)
          setList(_ => hist)->resolve
        | Error(msg) =>
          setHasError(_ => true)
          reject(FailedRequest("Error: " ++ msg))
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
  }, (loading, hasError))

  <div className="w-screen h-screen flex flex-row justify-center">
    <div className="w-frame h-full bg-white">
      <Header /> <Content list loading setLoading hasError setHasError />
    </div>
  </div>
}
