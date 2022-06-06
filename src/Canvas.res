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
  | EndCreation =>
    switch currFigure {
    | #polyline => {
        ...currState,
        shapes: currState.shapes->Js.Array2.map((shape: Shapes.t): Shapes.t => {
          let {id} = shape
          switch (currState.activeShapeId, shape.shape) {
          | (Some(asid), PolyVec(arr, fig)) if id == asid => {
              let arr = arr->Js.Array2.slice(~start=0, ~end_=arr->Js.Array2.length - 1)
              {id: id, shape: PolyVec(arr, fig)}
            }
          | _ => shape
          }
        }),
        activeShapeId: None,
        mode: Idle,
      }
    | _ => {...currState, activeShapeId: None, mode: Idle}
    }
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
    <div className="flex-col">
      <ShapeBtn
        isSelected={state.currFigure == #rect}
        onClick={_ => dispatch(ChangeCurrFigure(#rect))}
        label="Rect"
      />
      <ShapeBtn
        isSelected={state.currFigure == #circle}
        onClick={_ => dispatch(ChangeCurrFigure(#circle))}
        label="Circle"
      />
      <ShapeBtn
        isSelected={state.currFigure == #ellipse}
        onClick={_ => dispatch(ChangeCurrFigure(#ellipse))}
        label="Ellpise"
      />
      <ShapeBtn
        isSelected={state.currFigure == #line}
        onClick={_ => dispatch(ChangeCurrFigure(#line))}
        label="Line"
      />
      <ShapeBtn
        isSelected={state.currFigure == #polyline}
        onClick={_ => dispatch(ChangeCurrFigure(#polyline))}
        label="Polyline"
      />
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
