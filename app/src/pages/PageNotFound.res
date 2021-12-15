@react.component
let make = () => {
  <div className="h-content w-full flex flex-col justify-center items-center">
    {React.string("Oops, this page doesn't exist")}
    <button className="underline" onClick={_evt => RescriptReactRouter.push("/")}>
      {React.string("Go to dashboard")}
    </button>
  </div>
}
