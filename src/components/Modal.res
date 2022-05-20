module Input = {
  @react.component
  let make = (~label="", ~value: int, ~onChange) => {
    let onValueChange = React.useCallback0(e => {
      onChange(_ =>
        switch ReactEvent.Form.target(e)["value"]->Belt.Int.fromString {
        | Some(val) => val
        | _ => 0
        }
      )
    })
    <React.Fragment>
      <label className="text-sm text-gray-500"> {label->React.string} </label>
      <input
        type_="number"
        value={value->Belt.Int.toString}
        onChange={onValueChange}
        className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 mb-3 leading-tight focus:outline-none focus:shadow-outline"
      />
    </React.Fragment>
  }
}
@react.component
let make = (~setCanvasParams: (int, int) => unit) => {
  let (width, setWidth) = React.useState(_ => 500)
  let (height, setHeight) = React.useState(_ => 500)
  <div className="relative z-10" role="dialog">
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
    <div className="fixed z-10 inset-0 overflow-y-auto">
      <div
        className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <span className="hidden sm:inline-block sm:align-middle sm:h-screen" />
        <div
          className="relative inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div className="sm:flex sm:items-start">
              <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3 className="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                  {"Let's setup your workspace first"->React.string}
                </h3>
                <form className="mt-2">
                  <div className="text-sm text-gray-500">
                    <Input value={width} label="Width: " onChange={setWidth} />
                    <Input value={height} label="Height: " onChange={setHeight} />
                  </div>
                </form>
              </div>
            </div>
          </div>
          <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              onClick={_ => setCanvasParams(width, height)}
              className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
              {"Let's go!"->React.string}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
}
