let copyElementToClipboard = el => el->MyBindings.renderToStaticMarkup->MyBindings.copyText

type canvasParams = {width: int, height: int}

type coords = (int, int)

type figure = [#circle | #rect | #ellipse | #line | #polyline | #polygon]

type mode = Idle | Create(Shapes.id) | Selection(Shapes.id)

type action =
  | Click(coords)
  | Move(coords)
  | Release
  | EnterPressed
  | ChangeMode(mode)
  | ChangeCurrFigure(figure)

type state = {
  shapes: array<Shapes.t>,
  mode: mode,
  currFigure: figure,
}

let defaultState: state = {
  shapes: [],
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

let clickReducer = (x, y, state) => {
  let {mode, currFigure} = state
  switch mode {
  | Idle => {
      let shape = (x, y)->constructor(currFigure)
      {
        ...state,
        mode: Create(shape.id),
        shapes: state.shapes->Js.Array2.concat([shape]),
      }
    }
  | Create(id) =>
    switch currFigure {
    | #polyline => {
        ...state,
        shapes: state.shapes->Js.Array2.map(item => {
          if item.id == id {
            (x, y)->Shapes.updShape(item)
          } else {
            item
          }
        }),
      }
    | _ => state
    }
  | Selection(_) => failwith("Not implemented")
  }
}

let moveReducer = (x, y, state) => {
  let {mode, currFigure} = state
  switch mode {
  | Create(id) =>
    switch currFigure {
    | #polyline => {
        ...state,
        shapes: state.shapes->Js.Array2.map(item => {
          if item.id == id {
            (x, y)->Shapes.changePresence(item)
          } else {
            item
          }
        }),
      }
    | _ => {
        ...state,
        shapes: state.shapes->Js.Array2.map(item => {
          if item.id == id {
            (x, y)->Shapes.updShape(item)
          } else {
            item
          }
        }),
      }
    }
  | Idle => state
  | Selection(_) => failwith("Not implemented")
  }
}

let releaseReducer = state => {
  let {mode, currFigure} = state
  switch (mode, currFigure) {
  | (Create(_), #polyline) => state
  | (Create(_), _) => {...state, mode: Idle}
  | (Idle, _) => state
  | (Selection(_), _) => failwith("Not implemented")
  }
}

let enterPressedReducer = state => {
  let {mode, currFigure} = state
  switch (mode, currFigure) {
  | (Create(asid), #polyline) => {
      ...state,
      shapes: state.shapes->Js.Array2.map((item: Shapes.t): Shapes.t =>
        switch item.shape {
        | PolyVec(arr, fig) if item.id == asid => {
            let arr = arr->Js.Array2.slice(~start=0, ~end_=arr->Js.Array2.length - 1)
            {...item, shape: PolyVec(arr, fig)}
          }
        | _ => item
        }
      ),
      mode: Idle,
    }
  | _ => state
  }
}

let changeModeReducer = (mode, state) => {...state, mode: mode}

let changeCurrFigureReducer = (currFigure, state) => {...state, currFigure: currFigure}

let reducer = (state: state, action: action) => {
  state->switch action {
  | Click(x, y) => clickReducer(x, y)
  | Move(x, y) => moveReducer(x, y)
  | Release => releaseReducer
  | ChangeMode(mode) => changeModeReducer(mode)
  | ChangeCurrFigure(currFigure) => changeCurrFigureReducer(currFigure)
  | EnterPressed => enterPressedReducer
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
        dispatch(EnterPressed)
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
