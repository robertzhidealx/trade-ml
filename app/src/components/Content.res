open Types
open Utils

@react.component
let make = (
  ~list: array<transaction>,
  ~loading: bool,
  ~setLoading: (bool => bool) => unit,
  ~hasError: bool,
  ~setHasError: (bool => bool) => unit,
) => {
  let (amount, setAmount) = React.useState(_ => 0.)

  let handleStartGame = _evt => {
    open Promise
    let _ = {
      setLoading(_ => true)
      General.get("http://localhost:8080/init")
      ->then(ret => {
        switch ret {
        | Ok(_) =>
          setLoading(_ => false)
          setHasError(_ => false)
          resolve()
        | Error(msg) =>
          setLoading(_ => false)
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
    }
  }

  let handleInput = evt => {
    let val = ReactEvent.Form.target(evt)["value"]
    setAmount(_ => val)
  }

  let handleBuy = _evt => {
    open Promise
    let _ = {
      setLoading(_ => true)
      General.get(j`http://localhost:8080/buy?btc=$amount`)
      ->then(ret => {
        switch ret {
        | Ok(_) =>
          setLoading(_ => false)
          setHasError(_ => false)
          //           switch ReactDOM.querySelector("#t-list") {
          //           | Some(list) => %%raw("messageBody.scrollTop = messageBody.scrollHeight - messageBody.clientHeight;")
          // |None => ()
          //           }
          resolve()
        | Error(msg) =>
          setLoading(_ => false)
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
    }
  }

  let handleSell = _evt => {
    open Promise
    let _ = {
      setLoading(_ => true)
      General.get(j`http://localhost:8080/sell?btc=$amount`)
      ->then(ret => {
        switch ret {
        | Ok(_) =>
          setLoading(_ => false)
          setHasError(_ => false)
          resolve()
        | Error(msg) =>
          setLoading(_ => false)
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
    }
  }

  <div className="bg-frame w-full h-content flex flex-col-reverse pb-2">
    <div className="h-8 mt-2 px-6 w-full">
      {hasError
        ? <button
            className="w-full start-btn font-serif border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in"
            onClick={handleStartGame}
            disabled={loading}>
            {React.string("Start")}
          </button>
        : <div className="grid grid-cols-8 gap-x-2">
            <input
              defaultValue={Belt.Float.toString(amount)}
              onChange={handleInput}
              className="text-sm ml-1 font-serif border-2 border-white rounded-md outline-none hover:drop-shadow-lg transition duration-150 ease-in"
            />
            <button
              className="buy-btn font-serif border-2 border-white col-span-2 rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
              onClick={handleBuy}
              disabled={loading}>
              <img className="w-4 h-4" src="/svg/buy.svg" />
            </button>
            <button
              className="sell-btn font-serif border-2 border-white col-span-2 rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
              onClick={handleSell}
              disabled={loading}>
              <img className="w-4 h-4" src="/svg/sell.svg" />
            </button>
            <button
              className="convert-btn font-serif border-2 border-white col-span-2 rounded-md hover:drop-shadow-lg transition duration-150 ease-in">
              {React.string("Convert")}
            </button>
            <button
              className="font-serif border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
              onClick={handleStartGame}
              disabled={loading}>
              <img className="w-4 h-4" src="/svg/restart.svg" />
            </button>
          </div>}
    </div>
    {hasError ? <Error /> : <Transactions list />}
  </div>
}
