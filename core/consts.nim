import
  os

const
  pkgName*        = "min"
  pkgVersion*     = "0.19.2"
  pkgAuthor*      = "Fabio Cevasco"
  pkgDescription* = "A tiny concatenative programming language and shell."


var HOME*: string
if defined(windows):
  HOME = getenv("USERPROFILE")
if not defined(windows):
  HOME = getenv("HOME")

let MINRC* = HOME / ".minrc"
let MINSYMBOLS* = HOME / ".min_symbols"
let MINHISTORY* = HOME / ".min_history"
let MINLIBS* = HOME / ".minlibs"
