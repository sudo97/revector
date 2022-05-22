let copyElementToClipboard = el => el->MyBindings.renderToStaticMarkup->MyBindings.copyText

type canvasParams = {width: int, height: int}

type coords = (int, int)

type mode = Create(coords => Shapes.t) | Selection

type action = Start(coords) | Move(coords) | Release | Click(Shapes.id) | ChangeMode(mode)

type state = {
  shapes: array<Shapes.t>,
  activeShapeId: option<Shapes.id>,
  mode: mode,
}

let defaultState: state = {
  shapes: [],
  activeShapeId: None,
  mode: Create(Shapes.createCircle),
}

let reducer = (currState: state, action: action) => {
  let {mode} = currState
  switch action {
  | Start(x, y) =>
    switch mode {
    | Create(constructor) => {
        let shape = (x, y)->constructor
        {
          ...currState,
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
  | Click(_) => currState
  | ChangeMode(mode) => {...currState, mode: mode}
  }
}

@react.component
let make = (~params) => {
  let (width, height) = React.useMemo(
    ((), _) => (params.width->Belt.Int.toString, params.height->Belt.Int.toString),
    [params.width, params.height],
  )

  let (state, dispatch) = React.useReducer(reducer, defaultState)

  let onMouseDown = React.useCallback0(coords => Start(coords)->dispatch)
  let onMouseMove = React.useCallback0(coords => Move(coords)->dispatch)
  let onMouseUp = React.useCallback0(_ => dispatch(Release))

  let svgContent = <SVGImage width height onMouseDown onMouseMove onMouseUp shapes=state.shapes />

  <div className="flex flex-column">
    <div>
      <button className="bg-blue" onClick={_ => dispatch(ChangeMode(Create(Shapes.createRect)))}>
        {"Rect"->React.string}
      </button>
      <button className="bg-blue" onClick={_ => dispatch(ChangeMode(Create(Shapes.createCircle)))}>
        {"Circle"->React.string}
      </button>
      <button className="bg-blue" onClick={_ => dispatch(ChangeMode(Create(Shapes.createEllipse)))}>
        {"Ellipse"->React.string}
      </button>
      <button className="bg-blue" onClick={_ => dispatch(ChangeMode(Create(Shapes.createLine)))}>
        {"Line"->React.string}
      </button>
    </div>
    <div
      style={ReactDOMStyle.make(
        ~width=`${width}px`,
        ~height=`${height}px`,
        ~borderColor="black",
        ~border="solid",
        ~overflow="scroll",
        (),
      )}>
      {svgContent}
    </div>
  </div>
}
