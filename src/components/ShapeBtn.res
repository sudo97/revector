@react.component
let make = (~isSelected, ~onClick, ~label) => {
  let className =
    [
      ("block my-2 text-white font-bold py-2 px-4 rounded", true),
      ("bg-green-500 hover:bg-green-700", isSelected),
      ("bg-blue-500 hover:bg-blue-700", !isSelected),
    ]->Utils.className

  <button className onClick> {label->React.string} </button>
}
