@module("react-dom/server")
external renderToStaticMarkup: React.element => string = "renderToStaticMarkup"

@val @scope("navigator.clipboard")
external copyText: string => unit = "writeText"
