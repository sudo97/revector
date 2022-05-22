type t = array<(string, bool)>

let className = (arr: t): string =>
  arr
  ->Js.Array2.filter(((_, incl)) => incl)
  ->Js.Array2.map(((name, _)) => name)
  ->Js.Array2.joinWith(" ")
