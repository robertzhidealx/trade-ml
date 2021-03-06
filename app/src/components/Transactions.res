open Belt

let buy = "BUY"
let sell = "SELL"
let init = "INIT"

@react.component
let make = (~list: array<Types.transaction>) => {
  <div className="overflow-y-auto">
    <div className="w-full px-6 pt-2">
      {Array.map(list, tsn => {
        let {id, usd_bal, btc_bal, usd_amount, btc_amount, transaction_time, transaction_type} = tsn
        <div className="bg-white rounded-2xl" key={Int.toString(id)}>
          <Disclosure>
            {({open_}) => {
              <>
                <Disclosure.Button
                  className={`flex justify-between w-full px-4 py-2 text-sm font-medium text-left ${transaction_type ===
                      buy
                      ? "text-emerald-900"
                      : transaction_type === sell
                      ? "text-sky-900"
                      : ""} ${transaction_type === buy
                      ? "bg-emerald-200"
                      : transaction_type === sell
                      ? "bg-sky-200"
                      : "bg-gray-200"} ${open_
                      ? "rounded-t-2xl"
                      : "rounded-2xl"} ${transaction_type === buy
                      ? "hover:bg-emerald-300"
                      : transaction_type === sell
                      ? "hover:bg-sky-300"
                      : "hover:bg-gray-300"} focus:outline-none 
                      mt-2 transition duration-150 ease-in border-2 border-white`}>
                  <span>
                    {React.string(
                      (transaction_type === buy ? "+" : transaction_type === sell ? "-" : "") ++ (
                        transaction_type === init
                          ? "Game starts"
                          : Float.toString(btc_amount) ++ Js.String.fromCodePoint(0x20bf)
                      ),
                    )}
                  </span>
                  <div className="flex">
                    <span className="mr-2">
                      {React.string(Utils.timeToString(transaction_time))}
                    </span>
                    <Icons.ChevronUpIcon
                      className={`${open_
                          ? "transform rotate-180"
                          : ""} fill-white w-5 h-5 text-purple-500`}
                    />
                  </div>
                </Disclosure.Button>
                <Disclosure.Panel className="w-full px-4 py-2 text-sm text-gray-500">
                  <div className="grid grid-cols-4 w-full divide-x-2">
                    <div className="text-center">
                      {React.string(
                        j`${transaction_type === buy
                            ? Js.String.fromCodePoint(0x0394)
                            : transaction_type === sell
                            ? Js.String.fromCodePoint(0x2207)
                            : ""} ${transaction_type === init
                            ? "-"
                            : Float.toString(btc_amount) ++ Js.String.fromCodePoint(0x20bf)}`,
                      )}
                    </div>
                    <div className="text-center">
                      {React.string(
                        j`${transaction_type === buy
                            ? Js.String.fromCodePoint(0x2207)
                            : transaction_type === sell
                            ? Js.String.fromCodePoint(0x0394)
                            : ""} ${transaction_type === init
                            ? "-"
                            : "$" ++ Float.toString(usd_amount)}`,
                      )}
                    </div>
                    <div className="text-center">
                      {React.string(j`$btc_bal${Js.String.fromCodePoint(0x20bf)}`)}
                    </div>
                    <div className="text-center"> {React.string(j`\\$$usd_bal`)} </div>
                  </div>
                </Disclosure.Panel>
              </>
            }}
          </Disclosure>
        </div>
      })
      ->Array.reverse
      ->React.array}
    </div>
  </div>
}
