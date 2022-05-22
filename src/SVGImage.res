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
  let onMouseDown' = React.useCallback0(e => e->getCoords->onMouseDown)
  let onMouseMove' = React.useCallback0(e => e->getCoords->onMouseMove)
  let onMouseUp' = React.useCallback0(e => e->getCoords->onMouseUp)
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
      | _ => failwith("Not implemented")
      }
    })
    ->React.array}
  </svg>
}
