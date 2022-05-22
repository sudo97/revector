@module("react-dom/server")
external renderToStaticMarkup: React.element => string = "renderToStaticMarkup"

@val @scope("navigator.clipboard")
external copyText: string => unit = "writeText"

type evt = {key: string}
@val @scope("document")
external addDocEventListener: (. string, evt => unit) => unit = "addEventListener"

@val @scope("document")
external removeDocEventListener: (. string, evt => unit) => unit = "removeEventListener"
