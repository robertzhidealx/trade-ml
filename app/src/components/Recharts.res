module Utils = {
  type lineType = [
    | #basis
    | #basisClosed
    | #basisOpen
    | #linear
    | #linearClosed
    | #natural
    | #monotoneX
    | #monotoneY
    | #monotone
    | #step
    | #stepBefore
    | #stepAfter
  ]

  type margin = {"top": int, "right": int, "bottom": int, "left": int}

  type viewBox = {"x": int, "y": int, "width": int, "height": int}

  type padding = {"top": int, "right": int, "bottom": int, "left": int}

  type paddingHorizontal = {"right": int, "left": int}

  type paddingVertical = {"top": int, "bottom": int}

  type activeCoordinate = {"x": int, "y": int}

  module AxisInterval = {
    type t
    type arg =
      | PreserveStart
      | PreserveEnd
      | PreserveStartEnd
      | Num(int)
    let encode: arg => t = x =>
      switch x {
      | PreserveStart => Obj.magic("preserveStart")
      | PreserveEnd => Obj.magic("preserveEnd")
      | PreserveStartEnd => Obj.magic("preserveStartEnd")
      | Num(num) => Obj.magic(num)
      }
    let encodeOpt = Belt.Option.map(_, encode)
  }

  module PxOrPrc = {
    type t
    type arg =
      | Px(float)
      | Prc(float)
    let encode: arg => t = x =>
      switch x {
      | Px(v) => Obj.magic(v)
      | Prc(v) => Obj.magic(Js.Float.toString(v) ++ "%")
      }
    let encodeOpt = Belt.Option.map(_, encode)
  }

  module StrOrNode = {
    type t
    type arg =
      | Str(string)
      | Node(React.element)
    let encode: arg => t = x =>
      switch x {
      | Str(v) => Obj.magic(v)
      | Node(v) => Obj.magic(v)
      }
    let encodeOpt = Belt.Option.map(_, encode)
  }

  module TooltipCursor = {
    @deriving(abstract)
    type config = {
      @optional
      fill: string,
      @optional
      stroke: string,
      @optional
      strokeWidth: int,
    }

    type t
    type arg =
      | Bool(bool)
      | Config(config)
      | Component(React.element)
    let encode: arg => t = x =>
      switch x {
      | Bool(v) => Obj.magic(v)
      | Config(v) => Obj.magic(v)
      | Component(v) => Obj.magic(v)
      }
    let encodeOpt = Belt.Option.map(_, encode)
  }
}

module ResponsiveContainer = {
  // http://recharts.org/en-US/api/ResponsiveContainer
  open Utils
  @module("recharts") @react.component
  external make: (
    ~aspect: float=?,
    ~className: string=?,
    ~debounce: int=?,
    ~height: PxOrPrc.t=?,
    ~minHeight: int=?,
    ~minWidth: int=?,
    ~width: PxOrPrc.t=?,
    ~children: React.element,
  ) => React.element = "ResponsiveContainer"

  let makeProps = (~height=?, ~width=?) =>
    makeProps(~height=?height->PxOrPrc.encodeOpt, ~width=?width->PxOrPrc.encodeOpt)
}

module LineChart = {
  // https://recharts.org/en-US/api/LineChart
  open Utils
  @module("recharts") @react.component
  external make: (
    ~className: string=?,
    ~data: array<'dataItem>,
    ~height: int=?,
    ~layout: [#horizontal | #vertical]=?,
    ~margin: margin=?,
    ~onClick: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseUp: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseDown: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseEnter: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseLeave: ({..}, ReactEvent.Mouse.t) => unit=?,
    ~onMouseMove: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~syncId: string=?,
    ~width: int=?,
    ~children: React.element,
  ) => React.element = "LineChart"
}

module CartesianGrid = {
  // https://recharts.org/en-US/api/CartesianGrid
  @module("recharts") @react.component
  external make: (
    ~className: string=?,
    ~height: int=?,
    ~horizontal: bool=?,
    ~horizontalPoints: array<'horizontalPoints>=?,
    ~stroke: string=?,
    ~strokeDasharray: string=?,
    ~strokeWidth: int=?,
    ~vertical: bool=?,
    ~verticalPoints: array<'verticalPoints>=?,
    ~width: int=?,
    ~x: int=?,
    ~y: int=?,
  ) => React.element = "CartesianGrid"
}

module XAxis = {
  // https://recharts.org/en-US/api/XAxis
  open Utils
  @module("recharts") @react.component
  external make: (
    ~_type: [#number | #category]=?,
    ~allowDataOverflow: bool=?,
    ~allowDecimals: bool=?,
    ~allowDuplicatedCategory: bool=?,
    ~axisLine: 'axisLine=?,
    ~className: string=?,
    ~dataKey: string=?,
    ~domain: array<'domain>=?,
    ~height: int=?,
    ~hide: bool=?,
    ~interval: AxisInterval.t=?,
    ~label: 'label=?,
    ~minTickGap: int=?,
    ~mirror: bool=?,
    ~name: string=?,
    ~onClick: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseDown: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseEnter: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseLeave: ({..}, ReactEvent.Mouse.t) => unit=?,
    ~onMouseMove: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOut: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOver: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseUp: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~orientation: [#bottom | #top]=?,
    ~padding: paddingHorizontal=?,
    ~reversed: bool=?,
    ~scale: [
      | #auto
      | #linear
      | #pow
      | #sqrt
      | #log
      | #identity
      | #time
      | #band
      | #point
      | #ordinal
      | #quantile
      | #quantize
      | #utcTime
      | #sequential
      | #threshold
    ]=?,
    ~tick: 'tick=?,
    ~tickCount: int=?,
    ~tickFormatter: 'tickFormatter=?,
    ~tickLine: 'tickLine=?,
    ~tickMargin: int=?,
    ~ticks: array<'ticks>=?,
    ~tickSize: int=?,
    ~unit: string=?,
    ~width: int=?,
    ~xAxisId: string=?,
  ) => React.element = "XAxis"

  let makeProps = (~interval=?) => makeProps(~interval=?interval->AxisInterval.encodeOpt)
}

module YAxis = {
  // https://recharts.org/en-US/api/YAxis
  open Utils
  @module("recharts") @react.component
  external make: (
    ~_type: [#number | #category]=?,
    ~allowDataOverflow: bool=?,
    ~allowDecimals: bool=?,
    ~allowDuplicatedCategory: bool=?,
    ~axisLine: 'axisLine=?,
    ~className: string=?,
    ~dataKey: string=?,
    ~domain: array<'domain>=?,
    ~height: int=?,
    ~hide: bool=?,
    ~interval: AxisInterval.t=?,
    ~label: 'label=?,
    ~minTickGap: int=?,
    ~mirror: bool=?,
    ~name: string=?,
    ~onClick: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseDown: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseEnter: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseLeave: ({..}, ReactEvent.Mouse.t) => unit=?,
    ~onMouseMove: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOut: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOver: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseUp: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~orientation: [#left | #right]=?,
    ~padding: paddingVertical=?,
    ~reversed: bool=?,
    ~scale: [
      | #auto
      | #linear
      | #pow
      | #sqrt
      | #log
      | #identity
      | #time
      | #band
      | #point
      | #ordinal
      | #quantile
      | #quantize
      | #utcTime
      | #sequential
      | #threshold
    ]=?,
    ~tick: 'tick=?,
    ~tickFormatter: 'tickFormatter=?,
    ~tickLine: 'tickLine=?,
    ~tickMargin: int=?,
    ~ticks: array<'ticks>=?,
    ~tickSize: int=?,
    ~unit: string=?,
    ~width: int=?,
    ~yAxisId: string=?,
  ) => React.element = "YAxis"

  let makeProps = (~interval=?) => makeProps(~interval=?interval->AxisInterval.encodeOpt)
}

module Legend = {
  // http://recharts.org/en-US/api/Legend
  open Utils

  @module("recharts") @react.component
  external make: (
    ~align: [#left | #center | #right]=?,
    ~chartHeight: int=?,
    ~chartWidth: int=?,
    ~content: 'content=?,
    ~className: string=?,
    ~height: int=?,
    ~iconSize: int=?,
    ~iconType: [
      | #line
      | #square
      | #rect
      | #circle
      | #cross
      | #diamond
      | #star
      | #triangle
      | #wye
    ]=?,
    ~layout: [#horizontal | #vertical]=?,
    ~margin: margin=?,
    ~onClick: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseDown: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseEnter: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseLeave: ({..}, ReactEvent.Mouse.t) => unit=?,
    ~onMouseMove: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOut: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOver: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseUp: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~payload: array<{..}>=?,
    ~verticalAlign: [#top | #middle | #bottom]=?,
    ~width: int=?,
    ~wrapperStyle: {..}=?,
  ) => React.element = "Legend"
}

module Tooltip = {
  // http://recharts.org/en-US/api/Tooltip
  open Utils

  @module("recharts") @react.component
  external make: (
    ~active: bool=?,
    ~allowEscapeViewBox: {..}=?,
    ~animationBegin: int=?,
    ~animationDuration: int=?,
    ~animationEasing: [
      | #ease
      | @as("ease-in") #easeIn
      | @as("ease-out") #easeOut
      | @as("ease-in-out") #easeInOut
      | #linear
    ]=?,
    ~className: string=?,
    ~content: 'content=?,
    ~position: {..}=?,
    ~cursor: TooltipCursor.t=?,
    ~formatter: 'formatter=?,
    ~isAnimationActive: bool=?,
    ~itemSorter: 'itemSorter=?,
    ~itemStyle: {..}=?,
    ~label: string=?,
    ~labelFormatter: 'labelFormatter=?,
    ~labelStyle: {..}=?,
    ~offset: int=?,
    ~payload: array<{..}>=?,
    ~separator: string=?,
    ~viewBox: {..}=?,
    ~wrapperStyle: {..}=?,
  ) => React.element = "Tooltip"

  let makeProps = (~cursor=?) => makeProps(~cursor=?cursor->TooltipCursor.encodeOpt)
}

module Line = {
  // http://recharts.org/en-US/api/Line
  open Utils

  @module("recharts") @react.component
  external make: (
    ~_type: lineType=?,
    ~activeDot: 'activeDot=?,
    ~animationBegin: int=?,
    ~animationDuration: int=?,
    ~animationEasing: [
      | #ease
      | @as("ease-in") #easeIn
      | @as("ease-out") #easeOut
      | @as("ease-in-out") #easeInOut
      | #linear
    ]=?,
    ~className: string=?,
    ~connectNulls: bool=?,
    ~hide: bool=?,
    ~dataKey: 'dataKey,
    ~dot: 'dot=?,
    ~id: string=?,
    ~isAnimationActive: bool=?,
    ~label: 'label=?,
    ~layout: [#horizontal | #vertical]=?,
    ~legendType: [
      | #line
      | #square
      | #rect
      | #circle
      | #cross
      | #diamond
      | #square
      | #star
      | #triangle
      | #wye
    ]=?,
    ~name: string=?,
    ~onClick: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseDown: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseEnter: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseLeave: ({..}, ReactEvent.Mouse.t) => unit=?,
    ~onMouseMove: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOut: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseOver: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~onMouseUp: (Js.Nullable.t<{..}>, ReactEvent.Mouse.t) => unit=?,
    ~points: array<{..}>=?,
    ~stroke: string=?,
    ~strokeWidth: int=?,
    ~unit: string=?,
    ~xAxisId: string=?,
    ~yAxisId: string=?,
  ) => React.element = "Line"
}

module Brush = {
  // http://recharts.org/en-US/api/Brush
  open Utils

  @module("recharts") @react.component
  external make: (
    ~className: string=?,
    ~data: array<'data>=?,
    ~dataKey: 'dataKey,
    ~endIndex: int=?,
    ~fill: string=?,
    ~gap: int=?,
    ~height: int=?,
    ~onChange: {.."startIndex": int, "endIndex": int} => unit=?,
    ~padding: padding=?,
    ~startIndex: int=?,
    ~stroke: string=?,
    ~tickFormatter: 'tickFormatter=?,
    ~travellerWidth: int=?,
    ~width: int=?,
    ~x: int=?,
    ~y: int=?,
  ) => React.element = "Brush"
}
