module ChevronUpIcon = {
  @module("@heroicons/react/solid") @react.component
  external make: (~className: string=?) => React.element = "ChevronUpIcon"
}

module BuyIcon = {
  @module("@heroicons/react/solid") @react.component
  external make: (~className: string=?) => React.element = "PlusIcon"
}

module SellIcon = {
  @module("@heroicons/react/solid") @react.component
  external make: (~className: string=?) => React.element = "MinusIcon"
}

module RestartIcon = {
  @module("@heroicons/react/solid") @react.component
  external make: (~className: string=?) => React.element = "RefreshIcon"
}
