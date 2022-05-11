@react.component
let make = () => {
  let (params: option<Canvas.canvasParams>, setParams) = React.useState(_ => None)
  let setCanvasParams = React.useCallback0((width, height) =>
    setParams(_ => Some({width: width, height: height}))
  )
  <div>
    {switch params {
    | None => <Modal setCanvasParams />
    | Some(params) => <Canvas params />
    }}
  </div>
}

let default = make
