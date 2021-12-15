open Utils
open Recharts

@react.component
let make = () => {
  let (loading, setLoading) = React.useState(_ => false)
  let (hasError, setHasError) = React.useState(_ => false)
  let (visualization, setVisualization) = React.useState(_ => [])

  React.useEffect0(() => {
    open Promise
    let _ = {
      setLoading(_ => true)
      Visualization.get("http://localhost:8080/visualize")
      ->then(ret => {
        switch ret {
        | Ok(res) =>
          setLoading(_ => false)
          setHasError(_ => false)
          setVisualization(_ => res)->resolve
        | Error(msg) =>
          setLoading(_ => false)
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
    }
    None
  })

  let customTickX = props => {
    let (x, y, payload) = (props["x"], props["y"], props["payload"])

    <g transform={`translate(${x},${y})`}>
      <text x="0" y="0" dy="16" textAnchor="end" fill="#666" transform="rotate(-30)">
        {React.string(timeToString(payload["value"])->Js.String.substring(~from=11, ~to_=21, _))}
      </text>
    </g>
  }

  let customTickY = props => {
    let (x, y, payload) = (props["x"], props["y"], props["payload"])

    <g transform={`translate(${x},${y})`}>
      <text x="0" y="0" dy="16" textAnchor="end" fill="#666" transform="rotate(0)">
        {React.int(payload["value"]->Belt.Float.toInt)}
      </text>
    </g>
  }

  let customTooltipBtcPrice = props => {
    switch props["payload"] {
    | [] => <div />
    | payload =>
      <div className="bg-white opacity-70 p-2">
        <div> {timeToString(props["label"])->React.string} </div>
        <div className="text-[#8884d8]">
          {React.string({`BTC Price: ${payload[0]["value"]}`})}
        </div>
      </div>
    }
  }

  let customTooltipTotalAssets = props => {
    switch props["payload"] {
    | [] => <div />
    | payload =>
      <div className="bg-white opacity-70 p-2">
        <div> {timeToString(props["label"])->React.string} </div>
        <div className="text-[#82ca9d]">
          {React.string({`Total Assets: ${payload[0]["value"]}`})}
        </div>
      </div>
    }
  }

  <div className="bg-frame w-full h-content flex flex-col-reverse pb-2 px-6 items-center">
    <div className="w-full flex justify-between pt-2">
      <button
        className="w-8 h-8 start-btn font-serif border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex justify-center items-center"
        onClick={_evt => RescriptReactRouter.push("/")}>
        <Icons.ReplyIcon className="w-4 h-4" />
      </button>
    </div>
    {!loading && !hasError && Belt.Array.length(visualization) > 0
      ? <div className="h-full flex flex-col justify-center">
          <ResponsiveContainer height={Prc(45.)} width={Px(500.)}>
            <LineChart data={visualization} syncId="chart" className="relative -top-2 -left-7">
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="transaction_time" height={80} tick={customTickX} />
              <YAxis tick={customTickY} domain={["dataMin - 1000", "dataMax + 1000"]} />
              <Legend verticalAlign=#top />
              <Tooltip content={customTooltipBtcPrice} />
              <Line _type=#monotone dataKey="btc_price" stroke="#8884d8" />
              <Brush dataKey="" />
            </LineChart>
          </ResponsiveContainer>
          <ResponsiveContainer height={Prc(45.)} width={Px(500.)}>
            <LineChart data={visualization} syncId="chart" className="relative -top-2 -left-7">
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="transaction_time" height={80} tick={customTickX} />
              <YAxis tick={customTickY} domain={["dataMin - 100", "dataMax + 100"]} />
              <Legend verticalAlign=#top />
              <Tooltip content={customTooltipTotalAssets} />
              <Line _type=#monotone dataKey="total_assets" stroke="#82ca9d" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      : <div className="w-full h-full flex justify-center items-center italic">
          {React.string("You haven't traded anything yet :)")}
        </div>}
  </div>
}
