type input = {text: string, pos: int}

let makeInput = (s: string) => {text: s, pos: 0}

let inputSub = (s, start, len) => {
  pos: s.pos + start,
  text: s.text->Js.String2.substrAtMost(~from=start, ~length=len),
}

type t<'a> = {run: input => (input, option<'a>)}

let parsePrefix: string => t<string> = prefix => {
  run: inp => {
    let prefSize = prefix->Js.String2.length
    let inpSize = inp.text->Js.String2.length
    let prefInput = inp->inputSub(0, prefSize)
    if prefInput.text == prefix {
      let rest = inp->inputSub(prefSize, inpSize - prefSize)
      (rest, Some(prefix))
    } else {
      (inp, None)
    }
  },
}

let parseWhile: (string => bool) => t<string> = predicate => {
  run: input => {
    let rec loop = (inp, acc) => {
      let ch = inp.text->Js.String2.get(inp.pos)
      if ch->predicate {
        loop({...inp, pos: inp.pos + 1}, acc->Js.String2.concat(ch))
      } else {
        (inp, acc)
      }
    }
    let (input', res) = loop(input, "")
    (input', Some(res))
  },
}

let map: (t<'a>, 'a => 'b) => t<'b> = (p, f) => {
  run: inp => {
    let (inp', opt) = inp->p.run
    (inp', opt->Belt.Option.map(f))
  },
}

let isNumber = s => "1234567890"->Js.String2.split("")->Js.Array2.some(c => c == s)

@val external toInt: string => int = "Number"
@val external toFloat: string => float = "Number"

let parseNumber = parseWhile(isNumber)->map(toInt)
