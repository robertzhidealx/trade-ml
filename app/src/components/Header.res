@react.component
let make = () => {
  <div className="w-full h-14 flex flex-row justify-between p-4 border-b">
    <button
      className="font-serif text-xl font-medium mr-4"
      onClick={_evt => RescriptReactRouter.push("/")}>
      {React.string("TradeML")}
    </button>
    <a
      className="w-6 h-6"
      href="https://github.com/robertzhidealx/btc-game-monorepo"
      target="_blank"
      rel="noopener noreferrer">
      <img className="flex flex-row items-center" src="/svg/github.svg" />
    </a>
  </div>
}
