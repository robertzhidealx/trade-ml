open Utils
open Belt
open Types

@react.component
let make = (
  ~list: array<Types.transaction>,
  ~loading: bool,
  ~setLoading: (bool => bool) => unit,
  ~hasError: bool,
  ~setHasError: (bool => bool) => unit,
  ~wallet: Types.wallet,
) => {
  let (amount, setAmount) = React.useState(_ => 0.)
  let (typing, setTyping) = React.useState(_ => false)
  let (prediction, setPrediction) = React.useState(_ => {
    btc: 0.,
    real_usd_value: 0.,
    predicted_usd_value: 0.,
  })

  let handlePrediction = _evt => {
    open Promise
    let _ = {
      setLoading(_ => true)
      Prediction.get(j`http://localhost:8080/convert?btc=$amount&use_real=false`)
      ->then(ret => {
        switch ret {
        | Ok(res) =>
          setLoading(_ => false)
          setHasError(_ => false)
          let {btc, real_usd_value, predicted_usd_value} = res
          setPrediction(_ => {
            btc: btc,
            real_usd_value: Js.Float.toFixedWithPrecision(
              real_usd_value,
              ~digits=2,
            )->Js.Float.fromString,
            predicted_usd_value: Js.Float.toFixedWithPrecision(
              predicted_usd_value,
              ~digits=2,
            )->Js.Float.fromString,
          })
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

  React.useEffect1(() => {
    handlePrediction()
    None
  }, [amount])

  let handleStartGame = _evt => {
    open Promise
    let _ = {
      setLoading(_ => true)
      General.get(`http://localhost:8080/init?time=${Js.Date.now()->Float.toString}`)
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
      General.get(j`http://localhost:8080/buy?btc=$amount&time=${Js.Date.now()->Float.toString}`)
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

  let handleSell = _evt => {
    open Promise
    let _ = {
      setLoading(_ => true)
      General.get(j`http://localhost:8080/sell?btc=$amount&time=${Js.Date.now()->Float.toString}`)
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
    <div className="h-8 mt-2 px-6 w-full flex items-center">
      {hasError
        ? <button
            className="w-full start-btn font-serif border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in"
            onClick={handleStartGame}
            disabled={loading}>
            {React.string("Start")}
          </button>
        : <div className="w-full flex justify-between">
            <div className="flex items-center">
              <div
                className="h-6 rounded-lg bg-black text-white text-sm font-medium px-2 flex items-center mr-1.5">
                <div className="mr-0.5"> {React.string(Js.String.fromCodePoint(0x20bf))} </div>
                {React.float(wallet.btc_bal)}
              </div>
              <div
                className="h-6 rounded-lg bg-emerald-500 text-white text-sm font-medium px-2 flex items-center mr-1.5">
                <Icons.DollarIcon className="w-4 h-4" /> {React.float(wallet.usd_bal)}
              </div>
            </div>
            <div className="flex gap-1.5">
              <input
                defaultValue={Belt.Float.toString(amount)}
                onChange={handleInput}
                onFocus={_evt => setTyping(_ => true)}
                onBlur={_evt => setTyping(_ => false)}
                className="w-14 text-sm border-2 border-white rounded-md outline-none text-center"
              />
              <button
                className="w-12 buy-btn border-2 border-white col-span-2 rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
                onClick={handleBuy}
                disabled={loading}>
                <Icons.BuyIcon className="w-4 h-4" />
              </button>
              <button
                className="w-12 sell-btn border-2 border-white col-span-2 rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
                onClick={handleSell}
                disabled={loading}>
                <Icons.SellIcon className="w-4 h-4" />
              </button>
              <button
                className="w-6 border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
                onClick={_evt => RescriptReactRouter.push("/analytics")}
                disabled={loading}>
                <Icons.ChartIcon className="w-4 h-4" />
              </button>
              <button
                className="w-6 border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex flex-row justify-center items-center"
                onClick={handleStartGame}
                disabled={loading}>
                <Icons.RestartIcon className="w-4 h-4" />
              </button>
            </div>
          </div>}
    </div>
    {hasError
      ? <Error />
      : <>
          {typing
            ? <div className="px-6 pt-2 w-full">
                <div
                  className="w-full bg-gray-200 rounded-2xl h-[40px] border-2 border-white border-dashed flex items-center justify-between px-4 italic text-gray-500 text-sm">
                  <div>
                    {React.string(
                      `${prediction.btc->Float.toString}${Js.String.fromCodePoint(
                          0x20bf,
                        )} predicted = \\$${prediction.predicted_usd_value->Float.toString}, real-time = \\$${prediction.real_usd_value->Float.toString}`,
                    )}
                  </div>
                  <div>
                    {React.string(
                      Js.String.fromCodePoint(0x00b1) ++
                      prediction.real_usd_value->Float.toString ++ " USD",
                    )}
                  </div>
                </div>
              </div>
            : <div />}
          <Transactions list />
        </>}
  </div>
}
