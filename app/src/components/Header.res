@react.component
let make = (~wallet: Types.wallet) => {
  <div className="w-full h-14 flex flex-row justify-between p-4 border-b">
    <div className="flex flex-row items-center">
      <div className="font-serif text-xl font-medium mr-4"> {React.string("TradeML")} </div>
      <div className="rounded-lg bg-black text-white text-sm font-medium px-2 flex">
        <div className="mr-1"> {React.float(wallet.btc_bal)} </div>
        {React.string("|")}
        <div className="ml-1"> {React.float(wallet.usd_bal)} </div>
      </div>
    </div>
    <a
      className="w-6 h-6"
      href="https://github.com/robertzhidealx/btc-game-monorepo"
      target="_blank"
      rel="noopener noreferrer">
      <img className="flex flex-row items-center" src="/svg/github.svg" />
    </a>
  </div>
}
