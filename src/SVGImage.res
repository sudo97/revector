let getCoords = (e: ReactEvent.Mouse.t) => {
  let target = e->ReactEvent.Mouse.currentTarget
  let rect = target["getBoundingClientRect"](.)
  let clientX = e->ReactEvent.Mouse.clientX
  let x = clientX - rect["left"]
  let clientY = e->ReactEvent.Mouse.clientY
  let y = clientY - rect["top"]
  (x, y)
}

@react.component
let make = (
  ~width: string,
  ~height: string,
  ~onMouseDown,
  ~onMouseMove,
  ~onMouseUp,
  ~shapes: array<Shapes.t>,
) => {
  let onMouseDown' = React.useCallback1(e => e->getCoords->onMouseDown, [onMouseDown])
  let onMouseMove' = React.useCallback1(e => e->getCoords->onMouseMove, [onMouseMove])
  let onMouseUp' = React.useCallback1(e => e->getCoords->onMouseUp, [onMouseUp])
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width
    height
    viewBox={`0 0 ${width} ${height}`}
    version="1.1"
    baseProfile="full"
    onMouseDown=onMouseDown'
    onMouseMove=onMouseMove'
    onMouseUp=onMouseUp'>
    {shapes
    ->Js.Array2.map(({id, shape}) => {
      let key = id->Belt.Int.toString
      switch shape {
      | MonoVec(data, label) =>
        switch label {
        | #circle => <Shapes.Circle key data />
        | #ellipse => <Shapes.Ellipse key data />
        | #line => <Shapes.Line key data />
        | #rect => <Shapes.Rect key data />
        }
      | PolyVec(data, #polyline) => <Shapes.Polyline data key />
      | PolyVec(_, #polygon) => failwith("Not implemented")
      | Path => failwith("Not implemented")
      }
    })
    ->React.array}
  </svg>
}
