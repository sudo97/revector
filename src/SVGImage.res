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
type mode = Create(coords => Shapes.t)
type state = {
  shapes: array<Shapes.t>,
  shapeToDraw: option<Shapes.id>,
  mode: mode,
}

let defaultState: state = {
  shapes: [],
  shapeToDraw: None,
  mode: Create(Shapes.createCircle),
}

let reducer = (currState: state, action: mouseAction) => {
  switch action {
  | Start(x, y) =>
    switch currState.mode {
    | Create(constructor) => {
        let shape = (x, y)->constructor
        {
          ...currState,
          shapes: currState.shapes->Js.Array2.concat([shape]),
          shapeToDraw: Some(shape.id),
        }
      }
    }
  | Move(x, y) =>
    switch currState.shapeToDraw {
    | Some(id) =>
      switch currState.mode {
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
      }
    | _ => currState
    }
  | Release =>
    switch currState.mode {
    | Create(_) => {...currState, shapeToDraw: None}
    }
  | _ => currState
  }
}

@react.component
let make = (~width: string, ~height: string) => {
  let (state, dispatch) = React.useReducer(reducer, defaultState)

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
    ->Js.Array2.map(({id, shape: Circle(circle)}) =>
      <Shapes.Circle
        key={id->Belt.Int.toString}
        circle
        isSelected={switch state.shapeToDraw {
        | Some(id') => id == id'
        | _ => false
        }}
      />
    )
    ->React.array}
  </svg>
}
