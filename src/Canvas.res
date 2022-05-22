let copyElementToClipboard = el => el->MyBindings.renderToStaticMarkup->MyBindings.copyText

type canvasParams = {width: int, height: int}

@react.component
let make = (~params) => {
  let (width, height) = React.useMemo(
    ((), _) => (params.width->Belt.Int.toString, params.height->Belt.Int.toString),
    [params.width, params.height],
  )

  let (mode, setMode) = React.useState(_ => SVGImage.Create(Shapes.createCircle))

  let setCreator = React.useCallback0((c, _) => setMode(_ => SVGImage.Create(c)))

  let svgContent = <SVGImage width height mode />

  <div className="flex flex-column">
    <div>
      <button className="bg-blue" onClick={setCreator(Shapes.createRect)}>
        {"Rect"->React.string}
      </button>
      <button className="bg-blue" onClick={setCreator(Shapes.createCircle)}>
        {"Circle"->React.string}
      </button>
      <button className="bg-blue" onClick={setCreator(Shapes.createEllipse)}>
        {"Ellipse"->React.string}
      </button>
      <button className="bg-blue" onClick={setCreator(Shapes.createLine)}>
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
