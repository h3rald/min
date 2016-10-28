import
  critbits,
  terminal,
  queues,
  sequtils,
  strutils,
  os

# getch/putch implementations
when defined(windows):
   proc getchar*(): cint {.header: "<conio.h>", importc: "_getch".}
   proc putchar*(c: cint): cint {.discardable, header: "<conio.h>", importc: "_putch".}

   proc termSetup*() = 
     discard

   proc termSave*(): string = 
     return ""

   proc termRestore*() =
     discard
else:
  import osproc

  proc termSetup*() =
    discard execCmd "stty </dev/tty -icanon -echo -isig -iexten"

  proc termSave*(): string =
    let res = execCmdEx "stty </dev/tty -g"
    return res[0]

  let TERMSETTINGS* = termSave()
  proc termRestore*() =
    discard execCmd "stty </dev/tty " & TERMSETTINGS

  proc getchar*(): cint =
    return stdin.readChar().ord.cint

  proc putchar*(c: cint) =
    stdout.write(c.chr)

# Types

type
  Key* = int
  KeySeq* = seq[Key]
  KeyCallback* = proc(ed: var LineEditor)
  LineError* = ref Exception
  LineEditorError* = ref Exception
  LineEditorMode = enum
    mdInsert
    mdReplace
  Line = object
    text: string
    position: int
  LineHistory = object
    file: string
    tainted: bool
    position: int
    queue: Queue[string]
    max: int
  LineEditor* = object
    completionCallback*: proc(ed: LineEditor): seq[string]
    history: LineHistory
    line: Line
    mode: LineEditorMode

# Internal Methods

proc empty(line: Line): bool =
  return line.text.len <= 0

proc full(line: Line): bool =
  return line.position >= line.text.len

proc first(line: Line): int =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return 0

proc last(line: Line): int =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return line.text.len-1

proc fromStart(line: Line): string =
  if line.empty:
    return ""
  return line.text[line.first..line.position-1]

proc toEnd(line: Line): string =
  if line.empty:
    return ""
  return line.text[line.position..line.last]

proc back*(ed: var LineEditor, n=1) =
  if ed.line.position <= 0:
    return
  stdout.cursorBackward(n)
  ed.line.position = ed.line.position - n

proc forward*(ed: var LineEditor, n=1) = 
  if ed.line.full:
    return
  stdout.cursorForward(n)
  ed.line.position += n

proc `[]`( q: Queue[string], pos: int): string =
  var c = 0
  for e in q.items:
    if c == pos:
      result = e
      break
    c.inc

proc `[]=`( q: var Queue[string], pos: int, s: string) =
  var c = 0
  for e in q.mitems:
    if c == pos:
      e = s
      break
    c.inc

proc add(h: var LineHistory, s: string, force=false) =
  if s == "" and not force:
    return
  if h.queue.len >= h.max:
    discard h.queue.dequeue
  if h.tainted:
    h.queue[h.queue.len-1] = s
  else:
    h.queue.enqueue s

proc previous(h: var LineHistory): string =
  if h.queue.len == 0 or h.position <= 0:
    return nil
  h.position.dec
  result = h.queue[h.position]

proc next(h: var LineHistory): string =
  if h.queue.len == 0 or h.position >= h.queue.len-1:
    return nil
  h.position.inc
  result = h.queue[h.position]

# Public API

proc deletePrevious*(ed: var LineEditor) =
  if ed.line.position <= 0:
    return
  if not ed.line.empty:
    if ed.line.full:
      stdout.cursorBackward
      putchar(32)
      stdout.cursorBackward
      ed.line.position.dec
      ed.line.text = ed.line.text[0..ed.line.last-1]
    else:
      let rest = ed.line.toEnd & " "
      ed.back
      for i in rest:
        putchar i.ord
      ed.line.text = ed.line.fromStart & ed.line.text[ed.line.position+1..ed.line.last]
      stdout.cursorBackward(rest.len)
  
proc deleteNext*(ed: var LineEditor) =
  if not ed.line.empty:
    if not ed.line.full:
      let rest = ed.line.toEnd[1..^1] & " "
      for c in rest:
        putchar c.ord
      stdout.cursorBackward(rest.len)
      ed.line.text = ed.line.fromStart & ed.line.toEnd[1..^1]

proc printChar*(ed: var LineEditor, c: int) =  
  if ed.line.full:
    putchar(c.cint)
    ed.line.text &= c.chr
    ed.line.position += 1
  else:
    if ed.mode == mdInsert:
      putchar(c.cint)
      let rest = ed.line.toEnd
      ed.line.text.insert($c.chr, ed.line.position)
      ed.line.position += 1
      for j in rest:
        putchar(j.ord)
        ed.line.position += 1
      ed.back(rest.len)
    else: 
      putchar(c.cint)
      ed.line.text[ed.line.position] = c.chr
      ed.line.position += 1

proc changeLine*(ed: var LineEditor, s: string) =
  let text = ed.line.text
  let diff = text.len - s.len
  let position = ed.line.position
  if position > 0:
    stdout.cursorBackward(position)
  for c in s:
    putchar(c.ord)
  ed.line.position = s.len
  ed.line.text = s
  if diff > 0:
    for i in 0.countup(diff-1):
      putchar(32)
    stdout.cursorBackward(diff)

proc addToLineAtPosition(ed: var LineEditor, s: string) =
  for c in s:
    ed.printChar(c.ord)

proc clearLine*(ed: var LineEditor) =
  stdout.cursorBackward(ed.line.position+1)
  for i in ed.line.text:
    putchar(32)
  putchar(32)
  stdout.cursorBackward(ed.line.text.len)
  ed.line.position = 0
  ed.line.text = ""

proc goToStart*(ed: var LineEditor) =
  stdout.cursorBackward(ed.line.position)
  ed.line.position = 0

proc goToEnd*(ed: var LineEditor) =
  let diff = ed.line.text.len - ed.line.position
  stdout.cursorForward(diff)
  ed.line.position = ed.line.text.len

proc historyInit*(size = 256, historyFile: string = nil): LineHistory =
  result.file = historyFile
  result.queue = initQueue[string](size)
  result.position = 0
  result.tainted = false
  result.max = size
  if historyFile.isNil:
    return
  if result.file.fileExists:
    let lines = result.file.readFile.split("\n")
    for line in lines:
      if line != "":
        result.add line
    result.position = lines.len
  else:
    result.file.writeFile("")

proc historyAdd*(ed: var LineEditor, force = false) =
  ed.history.add ed.line.text, force
  if ed.history.file.isNil:
    return
  ed.history.file.writeFile(toSeq(ed.history.queue.items).join("\n"))

proc historyPrevious*(ed: var LineEditor) =
  let s = ed.history.previous
  if s.isNil:
    return
  let pos = ed.history.position
  var current: int
  if ed.history.tainted:
    current = ed.history.queue.len-2
  else:
    current = ed.history.queue.len-1
  if pos == current and ed.history.queue[current] != ed.line.text:
    ed.historyAdd(force = true)
    ed.history.tainted = true
  if s != "":
    ed.changeLine(s)
  
proc historyNext*(ed: var LineEditor) =
  let s = ed.history.next
  if s.isNil:
    return
  ed.changeLine(s)

proc historyFlush*(ed: var LineEditor) =
  if ed.history.queue.len > 0:
    ed.history.position = ed.history.queue.len
    ed.history.tainted = false

proc completeLine*(ed: var LineEditor): int =
  if ed.completionCallback.isNil:
    raise LineEditorError(msg: "Completion callback is not set")
  let compl = ed.completionCallback(ed)
  let position = ed.line.position
  let words = ed.line.fromStart.split(" ")
  var word: string
  if words.len > 0:
    word = words[words.len-1]
  else:
    word = ed.line.fromStart
  var matches = compl.filterIt(it.toLowerAscii.startsWith(word.toLowerAscii))
  if ed.line.fromStart.len > 0 and matches.len > 0:
    for i in 0..word.len-1:
      ed.deletePrevious
  var n = 0
  if matches.len > 0:
    ed.addToLineAtPosition(matches[0])
  else:
    return -1
  var ch = getchar()
  while ch == 9:
    n.inc
    if n < matches.len:
      let diff = ed.line.position - position
      for i in 0.countup(diff-1 + word.len):
        ed.deletePrevious
      ed.addToLineAtPosition(matches[n])
      ch = getchar()
    else:
      n = -1
  return ch

proc lineText*(ed: LineEditor): string =
  return ed.line.text
  
proc initEditor*(mode = mdInsert, historySize = 256, historyFile: string = nil): LineEditor =
  termSetup()
  result.mode = mode
  result.history = historyInit(historySize, historyFile)

# Character sets
const
  CTRL*        = {0 .. 31}
  DIGIT*       = {48 .. 57}
  LETTER*      = {65 .. 122}
  UPPERLETTER* = {65 .. 90}
  LOWERLETTER* = {97 .. 122}
  PRINTABLE*   = {32 .. 126}
when defined(windows):
  const
    ESCAPES* = {0, 22, 224}
else:
  const
    ESCAPES* = {27}


# Key Mappings
var KEYMAP*: CritBitTree[KeyCallBack]

KEYMAP["backspace"] = proc(ed: var LineEditor) =
  ed.deletePrevious()
KEYMAP["delete"] = proc(ed: var LineEditor) =
  ed.deleteNext()
KEYMAP["insert"] = proc(ed: var LineEditor) =
  if ed.mode == mdInsert:
    ed.mode = mdReplace
  else:
    ed.mode = mdInsert
KEYMAP["down"] = proc(ed: var LineEditor) =
  ed.historyNext()
KEYMAP["up"] = proc(ed: var LineEditor) =
  ed.historyPrevious()
KEYMAP["left"] = proc(ed: var LineEditor) =
  ed.back()
KEYMAP["right"] = proc(ed: var LineEditor) =
  ed.forward()
KEYMAP["ctrl+c"] = proc(ed: var LineEditor) =
  termRestore()
  quit(0)
KEYMAP["ctrl+x"] = proc(ed: var LineEditor) =
  ed.clearLine()
KEYMAP["ctrl+b"] = proc(ed: var LineEditor) =
  ed.goToStart()
KEYMAP["ctrl+e"] = proc(ed: var LineEditor) =
  ed.goToEnd()

# Key Names
var KEYNAMES*: array[0..31, string]
KEYNAMES[1]    =    "ctrl+a"
KEYNAMES[2]    =    "ctrl+b"
KEYNAMES[3]    =    "ctrl+c"
KEYNAMES[4]    =    "ctrl+d"
KEYNAMES[5]    =    "ctrl+e"
KEYNAMES[6]    =    "ctrl+f"
KEYNAMES[7]    =    "ctrl+g"
KEYNAMES[8]    =    "ctrl+h"
KEYNAMES[9]    =    "ctrl+i"
KEYNAMES[9]    =    "tab"
KEYNAMES[10]   =    "ctrl+j"
KEYNAMES[11]   =    "ctrl+k"
KEYNAMES[12]   =    "ctrl+l"
KEYNAMES[13]   =    "ctrl+m"
KEYNAMES[14]   =    "ctrl+n"
KEYNAMES[15]   =    "ctrl+o"
KEYNAMES[16]   =    "ctrl+p"
KEYNAMES[17]   =    "ctrl+q"
KEYNAMES[18]   =    "ctrl+r"
KEYNAMES[19]   =    "ctrl+s"
KEYNAMES[20]   =    "ctrl+t"
KEYNAMES[21]   =    "ctrl+u"
KEYNAMES[22]   =    "ctrl+v"
KEYNAMES[23]   =    "ctrl+w"
KEYNAMES[24]   =    "ctrl+x"
KEYNAMES[25]   =    "ctrl+y"
KEYNAMES[26]   =    "ctrl+z"

# Key Sequences
var KEYSEQS*: CritBitTree[KeySeq]

when defined(windows):
  KEYSEQS["up"]         = @[224, 72]
  KEYSEQS["down"]       = @[224, 80]
  KEYSEQS["right"]      = @[224, 77]
  KEYSEQS["left"]       = @[224, 75]
  KEYSEQS["insert"]     = @[224, 82]
  KEYSEQS["delete"]     = @[224, 83]
else:
  KEYSEQS["up"]         = @[27, 91, 65]
  KEYSEQS["down"]       = @[27, 91, 66]
  KEYSEQS["right"]      = @[27, 91, 67]
  KEYSEQS["left"]       = @[27, 91, 68]
  KEYSEQS["insert"]     = @[27, 91, 50, 126]
  KEYSEQS["delete"]     = @[27, 91, 51, 126]


proc readLine*(ed: var LineEditor, prompt="", hidechars = false): string =
  stdout.write(prompt)
  ed.line = Line(text: "", position: 0)
  var c = -1 # Used to manage completions
  while true:
    var c1: int
    if c > 0:
      c1 = c
      c = -1
    else:
      c1 = getchar()
    if c1 in {10, 13}:
      stdout.write("\n")
      ed.historyAdd()
      ed.historyFlush()
      return ed.line.text
    elif c1 in {8, 127}:
      KEYMAP["backspace"](ed)
    elif c1 in PRINTABLE:
      if hidechars:
        putchar('*'.ord)
        ed.line.text &= c1.chr
        ed.line.position.inc
      else:
        ed.printChar(c1)
    elif c1 == 9: # TAB
      c = ed.completeLine()
    elif c1 in ESCAPES:
      var s = newSeq[Key](0)
      s.add(c1)
      let c2 = getchar()
      s.add(c2)
      if s == KEYSEQS["left"]:
        KEYMAP["left"](ed)
      elif s == KEYSEQS["right"]:
        KEYMAP["right"](ed)
      elif s == KEYSEQS["up"]:
        KEYMAP["up"](ed)
      elif s == KEYSEQS["down"]:
        KEYMAP["down"](ed)
      elif s == KEYSEQS["delete"]:
        KEYMAP["delete"](ed)
      elif s == KEYSEQS["insert"]:
        KEYMAP["insert"](ed)
      elif c2 == 91:
        let c3 = getchar()
        s.add(c3)
        if s == KEYSEQS["right"]:
          KEYMAP["right"](ed)
        elif s == KEYSEQS["left"]:
          KEYMAP["left"](ed)
        elif s == KEYSEQS["up"]:
          KEYMAP["up"](ed)
        elif s == KEYSEQS["down"]:
          KEYMAP["down"](ed)
        elif c3 in {50, 51}:
          let c4 = getchar()
          s.add(c4)
          if c4 == 126 and c3 == 50:
            KEYMAP["insert"](ed)
          elif c4 == 126 and c3 == 51:
            KEYMAP["delete"](ed)
    elif KEYMAP.hasKey(KEYNAMES[c1]):
      KEYMAP[KEYNAMES[c1]](ed)

proc password*(ed: var LineEditor, prompt=""): string =
  return ed.readLine(prompt, true)
 
when isMainModule:
  proc testChar() =
    while true:
      let a = getch().ord
      echo "\n->", a
      if a == 3:
        termRestore()
        quit(0)
  proc testLineEditor() =
    while true:
      var ed = initEditor(historyFile = nil)
      echo "---", ed.readLine("-> "), "---"

  testChar()

