open Belt

@react.component
let make = (~list: array<Types.transaction>) => {
  let timeToString = (time: int) => {
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

  <div>
    <div className="w-full px-6 pt-2 overflow-y-auto">
      {Array.map(list, tsn =>
        <div className="bg-white rounded-2xl" key={Int.toString(tsn.id)}>
          <Disclosure>
            {({open_}) => {
              <>
                <Disclosure.Button
                  className={`flex justify-between w-full px-4 py-2 text-sm font-medium text-left ${tsn.transaction_type === "BUY"
                      ? "text-emerald-900"
                      : "text-sky-900"} ${tsn.transaction_type === "BUY"
                      ? "bg-emerald-200"
                      : "bg-sky-200"} ${open_
                      ? "rounded-t-lg"
                      : "rounded-lg"} ${tsn.transaction_type === "BUY"
                      ? "hover:bg-emerald-300"
                      : "hover:bg-sky-300"} focus:outline-none 
                      mt-2 transition duration-150 ease-in border-2 border-white`}>
                  <span> {React.string(timeToString(tsn.transaction_time))} </span>
                  <Icons.ChevronUpIcon
                    className={`${open_
                        ? "transform rotate-180"
                        : ""} fill-white w-5 h-5 text-purple-500`}
                  />
                </Disclosure.Button>
                <Disclosure.Panel className="px-4 py-2 text-sm text-gray-500">
                  {React.string("If you're unhappy with your purchase for any reason, email us
                within 90 days and we'll refund you in full, no questions asked.")}
                </Disclosure.Panel>
              </>
            }}
          </Disclosure>
        </div>
      )
      ->Array.reverse
      ->React.array}
    </div>
  </div>
}
