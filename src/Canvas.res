type canvasParams = {width: int, height: int}

let idGen = ref(0)

type coords = (int, int)

module Shapes = {
  type circle = {x: int, y: int, r: int}
  type variant = Circle(circle)
  type t = {id: int, shape: variant}
  let createCircle = (x, y) => {
    idGen.contents = idGen.contents + 1
    {shape: Circle({x: x, y: y, r: 0}), id: idGen.contents}
  }
}

type canvasState = {
  shapes: array<Shapes.t>,
  shapeToDraw: option<int>,
  shapeCreator: (int, int) => Shapes.t,
}

module Circle = {
  open Shapes
  @react.component
  let make = (~circle, ~isSelected=false) => {
    let cx = circle.x->Belt.Int.toString
    let cy = circle.y->Belt.Int.toString
    let r = circle.r->Belt.Int.toString
    <React.Fragment>
      <circle stroke="black" fill="none" cx cy r />
      {switch isSelected {
      | true => {
          let x = (circle.x - circle.r)->Belt.Int.toString
          let y = (circle.y - circle.r)->Belt.Int.toString
          let width = (circle.r * 2)->Belt.Int.toString
          <rect x y width height=width fill="none" stroke="black" strokeDasharray="5,5" />
        }
      | false => React.null
      }}
    </React.Fragment>
  }
}

module SVGImage = {
  let calcDistance = (x, x', y, y') => {
    let deltaX = Belt.Float.fromInt(x - x')
    let deltaY = Belt.Float.fromInt(y - y')
    (deltaX *. deltaX +. deltaY *. deltaY)->Js.Math.sqrt->Belt.Float.toInt
  }

  let updShape = (x', y', s: Shapes.variant) =>
    switch s {
    | Circle({x, y}) => Shapes.Circle({x: x, y: y, r: calcDistance(x, x', y, y')})
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

  type mouseAction = Start(coords) | Move(coords) | Release | Click

  let reducer = (currState: canvasState, action: mouseAction) =>
    switch action {
    | Start(x, y) => {
        let shape = currState.shapeCreator(x, y)
        {
          ...currState,
          shapeToDraw: Some(shape.id),
          shapes: currState.shapes->Js.Array2.concat([shape]),
        }
      }
    | Move(x, y) => {
        ...currState,
        shapes: currState.shapes->Js.Array2.map((item): Shapes.t => {
          let {id, shape} = item
          switch currState.shapeToDraw {
          | Some(id') if id' == id => {id: id, shape: updShape(x, y, shape)}
          | _ => {id: id, shape: shape}
          }
        }),
      }
    | Release => {...currState, shapeToDraw: None}
    | _ => currState
    }
  @react.component
  let make = (~width: string, ~height: string) => {
    let (state, dispatch) = React.useReducer(
      reducer,
      {shapes: [], shapeToDraw: None, shapeCreator: Shapes.createCircle},
    )
    let onMouseDown = React.useCallback0(e => {
      let target = e->ReactEvent.Mouse.target
      let currentTarget = e->ReactEvent.Mouse.currentTarget
      if target === currentTarget {
        e->getCoords->Start->dispatch
      }
    })

    let onMouseMove = React.useCallback0((e: ReactEvent.Mouse.t) => {
      let target = e->ReactEvent.Mouse.target
      let currentTarget = e->ReactEvent.Mouse.currentTarget
      if target === currentTarget {
        e->getCoords->Move->dispatch
      }
    })

    let onMouseUp = React.useCallback0(e => {
      let target = e->ReactEvent.Mouse.target
      let currentTarget = e->ReactEvent.Mouse.currentTarget
      if target === currentTarget {
        dispatch(Release)
      }
    })

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
        <Circle
          key={id->Belt.Int.toString}
          circle
          isSelected={switch state.shapeToDraw {
          | Some(id') if id == id' => true
          | _ => false
          }}
        />
      )
      ->React.array}
    </svg>
  }
}

let copyElementToClipboard = el => el->MyBindings.renderToStaticMarkup->MyBindings.copyText

@react.component
let make = (~params) => {
  let (width, height) = React.useMemo(
    ((), _) => (params.width->Belt.Int.toString, params.height->Belt.Int.toString),
    [params.width, params.height],
  )

  let svgContent = <SVGImage width height />

  <div className="flex flex-row">
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
