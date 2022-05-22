let copyElementToClipboard = el => el->MyBindings.renderToStaticMarkup->MyBindings.copyText

type canvasParams = {width: int, height: int}

type coords = (int, int)

type mode = Idle | Create | Selection

type figure = [#circle | #rect | #ellipse | #line | #polyline | #polygon]

type action =
  | Click(coords)
  | Move(coords)
  | Release
  | EndCreation
  | ChangeMode(mode)
  | ChangeCurrFigure(figure)

type state = {
  shapes: array<Shapes.t>,
  activeShapeId: option<Shapes.id>,
  mode: mode,
  currFigure: figure,
}

let defaultState: state = {
  shapes: [],
  activeShapeId: None,
  mode: Idle,
  currFigure: #circle,
}

let constructor = (coords, fig) => {
  coords->switch fig {
  | #circle => Shapes.createCircle
  | #rect => Shapes.createRect
  | #ellipse => Shapes.createEllipse
  | #line => Shapes.createLine
  | #polyline => Shapes.createPolyline
  | _ => failwith("constructor not implemented")
  }
}

let reducer = (currState: state, action: action) => {
  let {mode, currFigure} = currState
  switch action {
  | Click(x, y) =>
    switch mode {
    | Idle => {
        let shape = (x, y)->constructor(currFigure)
        {
          ...currState,
          mode: Create,
          shapes: currState.shapes->Js.Array2.concat([shape]),
          activeShapeId: Some(shape.id),
        }
      }
    | Create =>
      switch (currFigure, currState.activeShapeId) {
      | (#polyline, Some(id)) => {
          ...currState,
          shapes: currState.shapes->Js.Array2.map(item => {
            if item.id == id {
              (x, y)->Shapes.updShape(item)
            } else {
              item
            }
          }),
        }
      | _ => currState
      }
    | Selection => failwith("Not implemented")
    }
  | Move(x, y) =>
    switch currState.activeShapeId {
    | Some(id) =>
      switch (mode, currFigure) {
      | (Create, #polyline) => {
          ...currState,
          shapes: currState.shapes->Js.Array2.map(item => {
            if item.id == id {
              (x, y)->Shapes.changePresence(item)
            } else {
              item
            }
          }),
        }
      | (Create, _) => {
          ...currState,
          shapes: currState.shapes->Js.Array2.map(item => {
            if item.id == id {
              (x, y)->Shapes.updShape(item)
            } else {
              item
            }
          }),
        }
      | (Idle, _) => currState
      | (Selection, _) => failwith("Not implemented")
      }
    | None => currState
    }
  | Release =>
    switch (mode, currFigure) {
    | (Create, #polyline) => currState
    | (Create, _) => {...currState, activeShapeId: None, mode: Idle}
    | (Idle, _) => currState
    | (Selection, _) => failwith("Not implemented")
    }
  | ChangeMode(mode) => {...currState, mode: mode}
  | ChangeCurrFigure(currFigure) => {...currState, currFigure: currFigure}
  | EndCreation => {...currState, activeShapeId: None, mode: Idle}
  }
}

@react.component
let make = (~params) => {
  let (width, height) = React.useMemo(
    ((), _) => (params.width->Belt.Int.toString, params.height->Belt.Int.toString),
    [params.width, params.height],
  )

  let (state, dispatch) = React.useReducer(reducer, defaultState)

  let onMouseDown = React.useCallback0(coords => Click(coords)->dispatch)
  let onMouseMove = React.useCallback0(coords => Move(coords)->dispatch)
  let onMouseUp = React.useCallback0(_ => dispatch(Release))
  React.useEffect0(_ => {
    let handler = e => {
      open MyBindings
      if e.key == "Enter" {
        dispatch(EndCreation)
      }
    }
    MyBindings.addDocEventListener(. "keypress", handler)
    Some(
      _ => {
        MyBindings.removeDocEventListener(. "keypress", handler)
      },
    )
  })

  let svgContent = <SVGImage width height onMouseDown onMouseMove onMouseUp shapes=state.shapes />

  <div className="flex">
    <div>
      <div>
        <button className="block" onClick={_ => dispatch(ChangeCurrFigure(#rect))}>
          {"Rect"->React.string}
        </button>
        <button className="block" onClick={_ => dispatch(ChangeCurrFigure(#circle))}>
          {"Circle"->React.string}
        </button>
        <button className="block" onClick={_ => dispatch(ChangeCurrFigure(#ellipse))}>
          {"Ellipse"->React.string}
        </button>
        <button className="block" onClick={_ => dispatch(ChangeCurrFigure(#line))}>
          {"Line"->React.string}
        </button>
      </div>
      <div>
        <button className="block" onClick={_ => dispatch(ChangeCurrFigure(#polyline))}>
          {"Polyline"->React.string}
        </button>
      </div>
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
