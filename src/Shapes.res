type circle = {x: int, y: int, r: int}
type variant = Circle(circle)
type t = {id: int, shape: variant}
let calcDistance = (x, x', y, y') => {
  let deltaX = Belt.Float.fromInt(x - x')
  let deltaY = Belt.Float.fromInt(y - y')
  (deltaX *. deltaX +. deltaY *. deltaY)->Js.Math.sqrt->Belt.Float.toInt
}
type id = int
let idGen: ref<id> = ref(0)
let createCircle = ((x, y)) => {
  idGen.contents = idGen.contents + 1
  {shape: Circle({x: x, y: y, r: 0}), id: idGen.contents}
}
let updShape = ((x', y'), s: t) =>
  switch s.shape {
  | Circle({x, y}) => {...s, shape: Circle({x: x, y: y, r: calcDistance(x, x', y, y')})}
  }
module Circle = {
  @react.component
  let make = (~circle, ~isSelected=false, ~stroke="black", ~fill="none") => {
    let cx = circle.x->Belt.Int.toString
    let cy = circle.y->Belt.Int.toString
    let r = circle.r->Belt.Int.toString
    <React.Fragment>
      <circle stroke fill cx cy r />
      {if isSelected {
        let x = (circle.x - circle.r)->Belt.Int.toString
        let y = (circle.y - circle.r)->Belt.Int.toString
        let width = (circle.r * 2)->Belt.Int.toString
        <rect x y width height=width fill="none" stroke="black" strokeDasharray="5,5" />
      } else {
        React.null
      }}
    </React.Fragment>
  }
}
