module type SHAPE = {
  type t

  @react.component
  let make: (~data: t, ~isSelected: bool=?, ~stroke: string=?, ~fill: string=?) => React.element
}

type id = int
let idGen: ref<id> = ref(0)

type point = {x: int, y: int}
type vector = (point, point)

let calcDistance = ((point1, point2)) => {
  let deltaX = Belt.Float.fromInt(point1.x - point2.x)
  let deltaY = Belt.Float.fromInt(point1.y - point2.y)
  (deltaX *. deltaX +. deltaY *. deltaY)->Js.Math.sqrt->Belt.Float.toInt
}

let createVector = ((x, y)) => ({x: x, y: y}, {x: x, y: y})

module Circle: SHAPE with type t = vector = {
  type t = vector
  @react.component
  let make = (~data: t, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let (point1, _) = data
    let cx = point1.x->Belt.Int.toString
    let cy = point1.y->Belt.Int.toString
    let distance = calcDistance(data)
    let r = distance->Belt.Int.toString
    <React.Fragment>
      <circle stroke fill cx cy r />
      {if isSelected {
        let x = (point1.x - distance)->Belt.Int.toString
        let y = (point1.y - distance)->Belt.Int.toString
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
    let _ = isSelected
    let (point1, point2) = data
    let xVal = Js.Math.min_int(point1.x, point2.x)
    let yVal = Js.Math.min_int(point1.y, point2.y)
    let wVal = Js.Math.abs_int(point1.x - point2.x)
    let hVal = Js.Math.abs_int(point1.y - point2.y)
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
    let _ = isSelected
    let (point1, point2) = data
    let x = point1.x
    let y = point1.y
    let x' = point2.x
    let y' = point2.y
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
    let _ = isSelected
    let (point1, point2) = data
    let x1 = point1.x->Js.Int.toString
    let x2 = point2.x->Js.Int.toString
    let y1 = point1.y->Js.Int.toString
    let y2 = point2.y->Js.Int.toString
    <line x1 y1 x2 y2 fill stroke />
  }
}

module Polyline: SHAPE with type t = array<point> = {
  type t = array<point>
  @react.component
  let make = (~data, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let _ = isSelected
    let points =
      data
      ->Js.Array2.map(({x, y}) => `${x->Js.Int.toString} ${y->Js.Int.toString}`)
      ->Js.Array2.joinWith(", ")
    <React.Fragment> <polyline points stroke fill /> </React.Fragment>
  }
}

type idable<'a> = {id: id, shape: 'a}

type shape =
  | MonoVec(vector, [#circle | #rect | #ellipse | #line])
  | PolyVec(array<point>, [#polyline | #polygon])
  | Path

type t = idable<shape>

let makeMonoConstructor = (l, coords) => {
  idGen.contents = idGen.contents + 1
  {shape: MonoVec(coords->createVector, l), id: idGen.contents}
}

let createCircle = makeMonoConstructor(#circle)
let createRect = makeMonoConstructor(#rect)
let createEllipse = makeMonoConstructor(#ellipse)
let createLine = makeMonoConstructor(#line)

let createPolyline = ((x, y)) => {
  idGen.contents = idGen.contents + 1
  {shape: PolyVec([{x: x, y: y}, {x: x, y: y}], #polyline), id: idGen.contents}
}

let updShape = ((x, y), s: t): t =>
  switch s.shape {
  | MonoVec((point1, _), label) => {...s, shape: MonoVec((point1, {x: x, y: y}), label)}
  | PolyVec(points, label) => {
      ...s,
      shape: PolyVec(points->Js.Array2.concat([{x: x, y: y}]), label),
    }
  | Path => s
  }

let changePresence = ((x, y), s: t): t =>
  switch s.shape {
  | PolyVec(points, label) => {
      ...s,
      shape: PolyVec(
        points->Js.Array2.mapi((p, i) => {
          if i == points->Js.Array2.length - 1 {
            {x: x, y: y}
          } else {
            p
          }
        }),
        label,
      ),
    }
  | _ => s
  }
