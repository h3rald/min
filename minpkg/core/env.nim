import 
  os, 
  noise
  
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
var EDITOR* {.threadvar.}: Noise
EDITOR = Noise.init()
EDITOR.historyLoad(MINHISTORY)
var MINCOMPILED* {.threadvar.}: bool
MINCOMPILED = false
var DEV* {.threadvar.}: bool
DEV = false

