let getCoords = (e: ReactEvent.Mouse.t) => {
  let target = e->ReactEvent.Mouse.currentTarget
  let rect = target["getBoundingClientRect"](.)
  let clientX = e->ReactEvent.Mouse.clientX
  let x = clientX - rect["left"]
  let clientY = e->ReactEvent.Mouse.clientY
  let y = clientY - rect["top"]
  (x, y)
}

type coords = (int, int)

type mouseAction = Start(coords) | Move(coords) | Release | Click(Shapes.id)

type mode = Create(coords => Shapes.t) | Selection

type state = {
  shapes: array<Shapes.t>,
  activeShapeId: option<Shapes.id>,
}

let defaultState: state = {
  shapes: [],
  activeShapeId: None,
}

let reducer = (mode, currState: state, action: mouseAction) => {
  switch action {
  | Start(x, y) =>
    switch mode {
    | Create(constructor) => {
        let shape = (x, y)->constructor
        {
          shapes: currState.shapes->Js.Array2.concat([shape]),
          activeShapeId: Some(shape.id),
        }
      }
    | Selection => failwith("Not implemented")
    }
  | Move(x, y) =>
    switch currState.activeShapeId {
    | Some(id) =>
      switch mode {
      | Create(_) => {
          ...currState,
          shapes: currState.shapes->Js.Array2.map(item => {
            if item.id == id {
              (x, y)->Shapes.updShape(item)
            } else {
              item
            }
          }),
        }
      | Selection => failwith("Not implemented")
      }
    | _ => currState
    }
  | Release =>
    switch mode {
    | Create(_) => {...currState, activeShapeId: None}
    | Selection => failwith("Not implemented")
    }
  | _ => currState
  }
}

@react.component
let make = (~width: string, ~height: string, ~mode) => {
  let (state, dispatch) = React.useReducer(reducer(mode), defaultState)

  let onMouseDown = React.useCallback0(e => e->getCoords->Start->dispatch)
  let onMouseMove = React.useCallback0((e: ReactEvent.Mouse.t) => e->getCoords->Move->dispatch)
  let onMouseUp = React.useCallback0(_ => dispatch(Release))

  <svg
    xmlns="http://www.w3.org/2000/svg"
    width
    height
    viewBox={`0 0 ${width} ${height}`}
    version="1.1"
    baseProfile="full"
    onMouseDown
    onMouseMove
    onMouseUp>
    {state.shapes
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
