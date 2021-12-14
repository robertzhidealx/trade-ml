type disclosureRenderProps = {@as("open") open_: bool}

@module("@headlessui/react") @react.component
external make: (
  @as("as") ~as_: string=?,
  ~defaultOpen: bool=?,
  ~children: disclosureRenderProps => React.element,
  ~className: string=?,
) => React.element = "Disclosure"

type buttonRenderProps = {open_: bool}

module Button = {
  @module("@headlessui/react") @scope("Disclosure") @react.component
  external make: (
    @as("as") ~as_: string=?,
    ~children: React.element,
    ~className: string=?,
  ) => React.element = "Button"
}

type panelRenderProps = {open_: bool}

module Panel = {
  @module("@headlessui/react") @scope("Disclosure") @react.component
  external make: (
    @as("as") ~as_: string=?,
    ~static: bool=?,
    ~unmount: bool=?,
    ~children: React.element,
    ~className: string=?,
  ) => React.element = "Panel"
}
