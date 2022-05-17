type canvasParams = {width: int, height: int}

type coords = (int, int)

module Shapes = {
  type circle = {x: int, y: int, r: int}
  type variant = Circle(circle)
  type t = {id: int, shape: variant}
  let createCircle = (x, y) => {
    Circle({x: x, y: y, r: 0})
  }
}

type action = StartDrawing(coords) | KeepDrawing(coords) | EndDrawing | Edit(int)
type canvasState = {
  shapes: array<Shapes.t>,
  shapeToDraw: option<Shapes.variant>,
  shapeCreator: (int, int) => Shapes.variant,
}

module Circle = {
  open Shapes
  @react.component
  let make = (~circle, ~id=-1, ~dispatch: action => unit) => {
    let onClick = React.useCallback1(_ => dispatch(Edit(id)), [id])
    <circle
      stroke="black"
      fill="none"
      onClick
      cx={circle.x->Belt.Int.toString}
      cy={circle.y->Belt.Int.toString}
      r={circle.r->Belt.Int.toString}
    />
  }
}

let calcDistance = (x, x', y, y') => {
  let deltaX = Belt.Float.fromInt(x - x')
  let deltaY = Belt.Float.fromInt(y - y')
  (deltaX *. deltaX +. deltaY *. deltaY)->Js.Math.sqrt->Belt.Float.toInt
}

let idGen = ref(0)

let reducer = (currState: canvasState, action: action) =>
  switch action {
  | StartDrawing(x, y) => {...currState, shapeToDraw: Some(currState.shapeCreator(x, y))}
  | KeepDrawing(x', y') => {
      ...currState,
      shapeToDraw: currState.shapeToDraw->Belt.Option.map((Circle({x, y})) => Shapes.Circle({
        x: x,
        y: y,
        r: calcDistance(x, x', y, y'),
      })),
    }
  | EndDrawing =>
    switch currState.shapeToDraw {
    | Some(c) => {
        ...currState,
        shapeToDraw: None,
        shapes: currState.shapes->Belt.Array.concat([{id: idGen.contents, shape: c}]),
      }
    | _ => currState
    }
  | _ => currState
  }

let getCoords = (e: ReactEvent.Mouse.t) => {
  let target = e->ReactEvent.Mouse.target
  let rect = target["getBoundingClientRect"](.)
  let clientX = e->ReactEvent.Mouse.clientX
  let x = clientX - rect["left"]
  let clientY = e->ReactEvent.Mouse.clientY
  let y = clientY - rect["top"]
  (x, y)
}

@react.component
let make = (~params) => {
  let (width, height) = React.useMemo(
    ((), _) => (params.width->Belt.Int.toString, params.height->Belt.Int.toString),
    [params.width, params.height],
  )

  let (state, dispatch) = React.useReducer(
    reducer,
    {shapes: [], shapeToDraw: None, shapeCreator: Shapes.createCircle},
  )

  let onMouseDown = React.useCallback0(e => e->getCoords->StartDrawing->dispatch)

  let onMouseMove = React.useCallback0((e: ReactEvent.Mouse.t) => {
    let target = e->ReactEvent.Mouse.target
    let currentTarget = e->ReactEvent.Mouse.currentTarget
    if target === currentTarget {
      e->getCoords->KeepDrawing->dispatch
    }
  })

  let onMouseUp = React.useCallback0(_ => dispatch(EndDrawing))

  let svgContent =
    <svg
      width
      height
      viewBox={`0 0 ${width} ${height}`}
      version="1.1"
      baseProfile="full"
      onMouseDown
      onMouseMove
      onMouseUp>
      {state.shapes
      ->Belt.Array.map(({id, shape: Circle(circle)}) =>
        <Circle key={id->Belt.Int.toString} id dispatch circle />
      )
      ->React.array}
      {switch state.shapeToDraw {
      | Some(Circle(circle)) => <Circle circle dispatch />
      | None => React.null
      }}
    </svg>

  let svgxml = svgContent->MyBindings.renderToStaticMarkup

  let copySvg = _ => MyBindings.copyText(svgxml)

  <div className="flex flex-row">
    <div
      style={ReactDOMStyle.make(
        ~width=`${width}px`,
        ~height=`${height}px`,
        ~borderColor="black",
        ~border="solid",
        ~overflow="hidden",
        (),
      )}>
      {svgContent}
    </div>
    <div className="bg-gray-300 mx-10 flex-column w-80">
      <div className="font-mono text-justify"> {svgxml->React.string} </div>
    </div>
    <div>
      <button
        onClick={copySvg}
        className="inline-block px-6 py-2.5 bg-blue-600 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-blue-700 hover:shadow-lg focus:bg-blue-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-blue-800 active:shadow-lg transition duration-150 ease-in-out"
        type_="button">
        {"Copy"->React.string}
      </button>
    </div>
  </div>
}
