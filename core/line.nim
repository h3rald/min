import
  critbits,
  terminal,
  queues

# getch/putch implementations
when defined(windows):
   proc getchar(): cint {.header: "<conio.h>", importc: "_getch".}
   proc putchar(c: cint): cint {.discardable, header: "<conio.h>", importc: "_putch".}

   proc termSetup*() = 
     discard

   proc termSave*(): string = 
     return ""

   proc termRestore*(c: string) =
     discard
else:
  import osproc

  proc termSetup*() =
    discard execCmd "stty </dev/tty -icanon -echo -isig -iexten"

  proc termSave*(): string =
    let res = execCmdEx "stty </dev/tty -g"
    return res[0]

  proc termRestore*(c: string) =
    discard execCmd "stty </dev/tty " & c

  proc getchar(): cint =
    return stdin.readChar().ord.cint

  proc putchar(c: cint) =
    stdout.write(c.chr)


# Types

type
  Key* = int
  KeySeq* = seq[Key]
  LineError* = ref Exception
  LineEditorMode* = enum
    mdInsert
    mdReplace
  Line* = object
    text*: string
    position*: int
  KeyCallback* = proc(ed: var LineEditor)
  LineHistory* = object
    position*: int
    queue*: Queue[string]
    max*: int
  LineEditor* = object
    history: LineHistory
    line*: Line
    mode*: LineEditorMode

proc len*(line: Line): int =
  return line.text.len

proc empty*(line: Line): bool =
  return line.text.len == 0

proc full*(line: Line): bool =
  return line.position >= line.text.len

proc first*(line: Line): int =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return 0

proc last*(line: Line): int =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return line.text.len-1

proc fromFirst*(line: var Line): string =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return line.text[line.first..line.position-1]

proc toLast*(line: var Line): string =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return line.text[line.position..line.last]

proc back*(ed: var LineEditor, n=1) =
  if ed.line.empty:
    return
  stdout.cursorBackward(n)
  ed.line.position = ed.line.position - n

proc forward*(ed: var LineEditor, n=1) = 
  if ed.line.full:
    return
  stdout.cursorForward(n)
  ed.line.position += n

proc deletePrevious*(ed: var LineEditor) =
  if not ed.line.empty:
    if ed.line.full:
      stdout.cursorBackward
      putchar(32)
      stdout.cursorBackward
      ed.line.text = ed.line.text[0..ed.line.last-1]
    else:
      let rest = ed.line.toLast & " "
      ed.back
      for i in rest:
        putchar i.ord
      ed.line.text = ed.line.fromFirst & ed.line.text[ed.line.position+1..ed.line.last]
      stdout.cursorBackward(rest.len)
  
proc deleteNext*(ed: var LineEditor) =
  if not ed.line.empty:
    if not ed.line.full:
      let rest = ed.line.toLast[1..^1] & " "
      for c in rest:
        putchar c.ord
      stdout.cursorBackward(rest.len)
      ed.line.text = ed.line.fromFirst & ed.line.toLast[1..^1]

proc printChar*(ed: var LineEditor, c: int) =  
  if ed.line.full:
    putchar(c.cint)
    ed.line.text &= c.chr
    ed.line.position += 1
  else:
    if ed.mode == mdInsert:
      putchar(c.cint)
      let rest = ed.line.toLast
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

proc initHistory(size = 256): LineHistory =
  result.queue = initQueue[string](size)
  result.position = 0
  result.max = size

proc add(h: var LineHistory, s: string) =
  if s == "":
    return
  if h.queue.len >= h.max:
    discard h.queue.dequeue
  h.queue.enqueue s

proc addToHistory(ed: var LineEditor) =
  ed.history.add ed.line.text

proc initEditor*(mode = mdInsert, historySize = 256): LineEditor =
  result.mode =mode
  result.history = initHistory(historySize)


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

let TERMSETTINGS* = termSave()

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
  discard #TODO
KEYMAP["up"] = proc(ed: var LineEditor) =
  discard #TODO
KEYMAP["left"] = proc(ed: var LineEditor) =
  ed.back()
KEYMAP["right"] = proc(ed: var LineEditor) =
  ed.forward()
KEYMAP["ctrl+c"] = proc(ed: var LineEditor) =
  termRestore(TERMSETTINGS)
  quit(0)

# Key Names
var KEYNAMES*: array[0..31, string]
KEYNAMES[3] = "ctrl+c"


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


proc readLine*(ed: var LineEditor, prompt=""): string =
  termSetup()
  stdout.write(prompt)
  ed.line = Line(text: "", position: 0)
  while true:
    let c1 = getchar()
    if c1 in {10, 13}:
      termRestore(TERMSETTINGS)
      ed.addToHistory()
      return ed.line.text
    elif c1 in {8, 127}:
      KEYMAP["backspace"](ed)
    elif c1 in PRINTABLE:
      ed.printChar(c1)
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
        elif c3 in {50, 51}:
          let c4 = getchar()
          s.add(c4)
          if c4 == 126 and c3 == 50:
            KEYMAP["insert"](ed)
          elif c4 == 126 and c3 == 51:
            KEYMAP["delete"](ed)
    elif KEYMAP.hasKey(KEYNAMES[c1]):
      KEYMAP[KEYNAMES[c1]](ed)

 
when isMainModule:
  var ed = initEditor()
  while true:
    echo "\n---", ed.readLine("-> "), "---"
