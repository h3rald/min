import
  std/os,
  minline

var HOME* {.threadvar.}: string
if defined(windows):
  HOME = getenv("USERPROFILE")
if not defined(windows):
  HOME = getenv("HOME")

var MMMREGISTRY* {.threadvar.}: string
MMMREGISTRY = "https://min-lang.org"
var MINRC* {.threadvar.}: string
MINRC = HOME / ".minrc"
var MINSYMBOLS* {.threadvar.}: string
MINSYMBOLS = HOME / ".min_symbols"
var MINHISTORY* {.threadvar.}: string
MINHISTORY = HOME / ".min_history"
var EDITOR* {.threadvar.}: LineEditor
EDITOR = initEditor(historyFile = MINHISTORY)
var MINCOMPILED* {.threadvar.}: bool
MINCOMPILED = false
var DEV* {.threadvar.}: bool
DEV = false
var COLOR* {.threadvar.}: bool
COLOR = true
var ERRORS_HANDLED* {.threadvar.}: bool
ERRORS_HANDLED = false
