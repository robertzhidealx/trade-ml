open Types
open Utils

@react.component
let make = () => {
  let (list: array<transaction>, setList) = React.useState(_ => [])
  let (wallet: wallet, setWallet) = React.useState(_ => {usd_bal: 0., btc_bal: 0., msg: ""})
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

    let _ =
      General.get("http://localhost:8080/wallet")
      ->then(ret => {
        switch ret {
        | Ok(res) =>
          setHasError(_ => false)
          setWallet(_ => res)->resolve
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

  let url = RescriptReactRouter.useUrl()

  <div className="w-screen h-screen flex flex-row justify-center">
    <div className="w-frame h-full bg-white">
      <Header />
      {switch url.path {
      | list{"analytics"} => <Analytics />
      | list{} => <Dashboard list loading setLoading hasError setHasError wallet />
      | _ => <PageNotFound />
      }}
    </div>
  </div>
}
