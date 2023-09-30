import
  std/os,
  minline

var HOME*: string
if defined(windows):
  HOME = getenv("USERPROFILE")
if not defined(windows):
  HOME = getenv("HOME")

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

