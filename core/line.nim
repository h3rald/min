import
  critbits,
  terminal

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
  LineEditingMode* = enum
    mdInsert
    mdReplace
  Line* = object
    text*: string
    position*: int
    mode*: LineEditingMode
  KeyCallback* = proc(ln: var Line)

proc len*(ln: Line): int =
  return ln.text.len

proc empty*(ln: Line): bool =
  return ln.text.len == 0

proc full*(ln: Line): bool =
  return ln.position >= ln.text.len

proc first*(ln: Line): int =
  if ln.empty:
    raise LineError(msg: "Line is empty!")
  return 0

proc last*(ln: Line): int =
  if ln.empty:
    raise LineError(msg: "Line is empty!")
  return ln.text.len-1

proc back*(ln: var Line, n=1) =
  if ln.empty:
    return
  stdout.cursorBackward(n)
  ln.position = ln.position - n

proc forward*(ln: var Line, n=1) = 
  if ln.full:
    return
  stdout.cursorForward(n)
  ln.position += n

proc fromFirst*(ln: var Line): string =
  if ln.empty:
    raise LineError(msg: "Line is empty!")
  return ln.text[ln.first..ln.position-1]

proc toLast*(ln: var Line): string =
  if ln.empty:
    raise LineError(msg: "Line is empty!")
  return ln.text[ln.position..ln.last]

proc deletePrevious*(ln: var Line) =
  if not ln.empty:
    if ln.full:
      stdout.cursorBackward
      putchar(32)
      stdout.cursorBackward
      ln.text = ln.text[0..ln.last-1]
    else:
      let rest = ln.toLast & " "
      ln.back
      for i in rest:
        putchar i.ord
      ln.text = ln.fromFirst & ln.text[ln.position+1..ln.last]
      stdout.cursorBackward(rest.len)
  
proc printChar*(ln: var Line, c: int) =  
  if ln.full:
    putchar(c.cint)
    ln.text &= c.chr
    ln.position += 1
  else:
    if ln.mode == mdInsert:
      putchar(c.cint)
      let rest = ln.toLast
      ln.text.insert($c.chr, ln.position)
      ln.position += 1
      for j in rest:
        putchar(j.ord)
        ln.position += 1
      ln.back(rest.len)
    else: 
      putchar(c.cint)
      ln.text &= c.chr
      ln.position += 1

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

KEYMAP["backspace"] = proc(ln: var Line) =
  ln.deletePrevious()
KEYMAP["delete"] = proc(ln: var Line) =
  discard #TODO
KEYMAP["down"] = proc(ln: var Line) =
  discard #TODO
KEYMAP["up"] = proc(ln: var Line) =
  discard #TODO
KEYMAP["left"] = proc(ln: var Line) =
  ln.back()
KEYMAP["right"] = proc(ln: var Line) =
  ln.forward()
KEYMAP["ctrl+c"] = proc(ln: var Line) =
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
  

proc readLine*(prompt="", history=false): string =
  termSetup()
  stdout.write(prompt)
  var line = Line(text: "", position: 0, mode: mdInsert)
  while true:
    let c1 = getchar()
    if c1 in {10, 13}:
      termRestore(TERMSETTINGS)
      return line.text
    elif c1 in {8, 127}:
      KEYMAP["backspace"](line)
    elif c1 in PRINTABLE:
      line.printChar(c1)
    elif c1 in ESCAPES:
      var s = newSeq[Key](0)
      s.add(c1)
      let c2 = getchar()
      s.add(c2)
      if s == KEYSEQS["left"]:
        KEYMAP["left"](line)
      elif s == KEYSEQS["right"]:
        KEYMAP["right"](line)
      elif s == KEYSEQS["up"]:
        KEYMAP["up"](line)
      elif s == KEYSEQS["down"]:
        KEYMAP["down"](line)
      elif s == KEYSEQS["delete"]:
        KEYMAP["delete"](line)
      elif s == KEYSEQS["insert"]:
        KEYMAP["insert"](line)
      elif c2 == 91:
        let c3 = getchar()
        s.add(c3)
        if s == KEYSEQS["right"]:
          KEYMAP["right"](line)
        elif s == KEYSEQS["left"]:
          KEYMAP["left"](line)
        elif c3 in {50, 51}:
          let c4 = getchar()
          s.add(c4)
          if c4 == 126 and c3 == 50:
            KEYMAP["insert"](line)
          elif c4 == 126 and c3 == 51:
            KEYMAP["delete"](line)
    elif KEYMAP.hasKey(KEYNAMES[c1]):
      KEYMAP[KEYNAMES[c1]](line)

when isMainModule:
  echo "\n---", readLine("-> "), "---"
