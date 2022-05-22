module type SHAPE = {
  type t

  @react.component
  let make: (~data: t, ~isSelected: bool=?, ~stroke: string=?, ~fill: string=?) => React.element
}

type id = int
let idGen: ref<id> = ref(0)

type vector = {x: int, y: int, x': int, y': int}

let calcDistance = ({x, x', y, y'}) => {
  let deltaX = Belt.Float.fromInt(x - x')
  let deltaY = Belt.Float.fromInt(y - y')
  (deltaX *. deltaX +. deltaY *. deltaY)->Js.Math.sqrt->Belt.Float.toInt
}

let createVector = ((x, y)) => {x: x, y: y, x': x, y': y}

module Circle: SHAPE with type t = vector = {
  type t = vector
  @react.component
  let make = (~data: t, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let cx = data.x->Belt.Int.toString
    let cy = data.y->Belt.Int.toString
    let distance = calcDistance(data)
    let r = distance->Belt.Int.toString
    <React.Fragment>
      <circle stroke fill cx cy r />
      {if isSelected {
        let x = (data.x - distance)->Belt.Int.toString
        let y = (data.y - distance)->Belt.Int.toString
        let width = (distance * 2)->Belt.Int.toString
        <rect x y width height=width fill="none" stroke="black" strokeDasharray="5,5" />
      } else {
        React.null
      }}
    </React.Fragment>
  }
}

module Rect: SHAPE with type t = vector = {
  type t = vector
  @react.component
  let make = (~data, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let xVal = Js.Math.min_int(data.x', data.x)
    let yVal = Js.Math.min_int(data.y', data.y)
    let wVal = Js.Math.abs_int(data.x - data.x')
    let hVal = Js.Math.abs_int(data.y - data.y')
    let x = xVal->Belt.Int.toString
    let y = yVal->Belt.Int.toString
    let width = wVal->Js.Math.abs_int->Belt.Int.toString
    let height = hVal->Js.Math.abs_int->Belt.Int.toString
    <rect x y width height fill stroke />
  }
}

module Ellipse: SHAPE with type t = vector = {
  type t = vector
  @react.component
  let make = (~data, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let {x, x', y, y'} = data
    let cx = Js.Math.min_int(x, x')->Js.Int.toString
    let cy = Js.Math.min_int(y, y')->Js.Int.toString
    let rx = (x - x')->Js.Math.abs_int->Js.Int.toString
    let ry = (y - y')->Js.Math.abs_int->Js.Int.toString
    <ellipse cx cy rx ry stroke fill />
  }
}

module Line: SHAPE with type t = vector = {
  type t = vector
  @react.component
  let make = (~data, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let x1 = data.x->Js.Int.toString
    let x2 = data.x'->Js.Int.toString
    let y1 = data.y->Js.Int.toString
    let y2 = data.y'->Js.Int.toString
    <line x1 y1 x2 y2 fill stroke />
  }
}
type idable<'a> = {id: id, shape: 'a}

type shape =
  | MonoVec(vector, [#circle | #rect | #ellipse | #line])
  | PolyVec(array<vector>, [#polyline | #polygon])
  | Path

type t = idable<shape>

let makeConstructor = (l, coords) => {
  idGen.contents = idGen.contents + 1
  {shape: MonoVec(coords->createVector, l), id: idGen.contents}
}

let createCircle = makeConstructor(#circle)
let createRect = makeConstructor(#rect)
let createEllipse = makeConstructor(#ellipse)
let createLine = makeConstructor(#line)

let updShape = ((x', y'), s: t): t =>
  switch s.shape {
  | MonoVec(vec, label) => {...s, shape: MonoVec({...vec, x': x', y': y'}, label)}
  | _ => s
  }
