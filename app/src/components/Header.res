@react.component
let make = () => {
  <div className="w-full h-14 flex flex-row justify-between p-4 border-b">
    <div className="flex flex-row items-center font-serif text-xl font-medium">
      {React.string("TradeML")}
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
