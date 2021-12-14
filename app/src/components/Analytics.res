open Recharts

@react.component
let make = (~loading: bool, ~data) => {
  <div className="bg-frame w-full h-content flex flex-col-reverse pb-2 px-6 items-center">
    <div className="w-full flex justify-between pt-2">
      <button
        className="w-8 h-8 start-btn font-serif border-2 border-white rounded-md hover:drop-shadow-lg transition duration-150 ease-in flex justify-center items-center"
        disabled={loading}
        onClick={_evt => RescriptReactRouter.push("/")}>
        <Icons.ReplyIcon className="w-4 h-4" />
      </button>
    </div>
    <ResponsiveContainer height={Px(200.)} width={Px(300.)} className="bg-white rounded-2xl p-4">
      <LineChart data className="relative -top-2 -left-7">
        <Line _type=#monotone dataKey="uv" /> <XAxis dataKey="uv" /> <YAxis />
      </LineChart>
    </ResponsiveContainer>
  </div>
}
