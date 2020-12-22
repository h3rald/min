import 
  strutils,
  logging,
  critbits,
  terminal
import 
  ../packages/nimline/nimline,
  ../packages/nim-sgregex/sgregex,
  ../core/parser, 
  ../core/value, 
  ../core/env,
  ../core/interpreter, 
  ../core/utils

var ORIGKEYMAP {.threadvar.}: CritBitTree[KeyCallback] 
for key, value in KEYMAP.pairs:
  ORIGKEYMAP[key] = value

proc io_module*(i: In) =
  let def = i.define()

  def.symbol("clear") do (i: In):
    stdout.eraseScreen
    stdout.setCursorPos(0, 0)

  def.symbol("unmapkey") do (i: In):
    let vals = i.expect("'sym")
    let key = vals[0].getString.toLowerAscii
    if not KEYNAMES.contains(key) and not KEYSEQS.contains(key):
      raiseInvalid("Unrecognized key: " & key)
    if KEYMAP.hasKey(key):
      if ORIGKEYMAP.hasKey(key):
        KEYMAP[key] = ORIGKEYMAP[key]
      else:
        KEYMAP.excl(key)

  def.symbol("mapkey") do (i: In):
    let vals = i.expect("'sym", "quot")
    let key = vals[0].getString.toLowerAscii
    var q = vals[1]
    if not KEYNAMES.contains(key) and not KEYSEQS.contains(key):
      raiseInvalid("Unrecognized key: " & key)
    var ic = i.copy(i.filename)
    KEYMAP[key] = proc (ed: var LineEditor) {.gcsafe.} =
      ic.apply(q)
  
  def.symbol("newline") do (i: In):
    echo ""
  
  def.symbol("notice") do (i: In):
    let a = i.peek
    notice $$a

  def.symbol("info") do (i: In):
    let a = i.peek
    info $$a

  def.symbol("error") do (i: In):
    let a = i.peek
    error $$a

  def.symbol("warn") do (i: In):
    let a = i.peek
    warn $$a

  def.symbol("debug") do (i: In):
    let a = i.peek
    debug $$a

  def.symbol("fatal") do (i: In):
    let a = i.peek
    fatal $$a
    quit(100)

  def.symbol("column-print") do (i: In):
    let vals = i.expect("int", "quot")
    let n = vals[0]
    let q = vals[1]
    var c = 0
    for s in q.qVal:
      c.inc
      stdout.write $$s & spaces(max(0, 15 - ($$s).len))
      if c mod n.intVal == 0:
        echo ""
    echo ""

  def.symbol("getchr") do (i: In):
    i.push getchr().newVal

  def.symbol("putchr") do (i: In):
    let ch = i.expect("string")
    if ch[0].getString.len != 1:
      raiseInvalid("Symbol putch requires a string containing a single character.")
    putchr(ch[0].getString[0].cint)

  def.symbol("password") do (i: In) {.gcsafe.}:
    var ed = initEditor()
    i.push ed.password("Enter Password: ").newVal

  def.symbol("ask") do (i: In) {.gcsafe.}:
    var ed = initEditor()
    let vals = i.expect("string")
    let s = vals[0]
    i.push ed.readLine(s.getString & ": ").newVal

  def.symbol("confirm") do (i: In) {.gcsafe.}:
    var ed = initEditor()
    let vals = i.expect("string")
    let s = vals[0]
    proc confirm(): bool =
      let answer = ed.readLine(s.getString & " [yes/no]: ")
      if answer.match("^y(es)?$", "i"):
        return true
      elif answer.match("^no?$", "i"):
        return false
      else:
        stdout.write "Invalid answer. Please enter 'yes' or 'no': "
        return confirm()
    i.push confirm().newVal

  def.symbol("choose") do (i: In) {.gcsafe.}:
    var ed = initEditor()
    let vals = i.expect("'sym", "quot")
    let s = vals[0]
    var q = vals[1]
    if q.qVal.len <= 0:
      raiseInvalid("No choices to display")
    stdout.writeLine(s.getString)
    proc choose(): int =
      var c = 0
      for item in q.qVal:
        if not item.isQuotation or not item.qVal.len == 2 or not item.qVal[0].isString or not item.qVal[1].isQuotation:
          raiseInvalid("Each item of the quotation must be a quotation containing a string and a quotation")
        c.inc
        echo "$1 - $2" % [$c, item.qVal[0].getString]
      let answer = ed.readLine("Enter your choice ($1 - $2): " % ["1", $c])
      var choice: int
      try:
        choice = answer.parseInt
      except:
        choice = 0
      if choice <= 0 or choice > c:
        echo "Invalid choice."
        return choose()
      else:
        return choice
    let choice = choose()
    i.dequote(q.qVal[choice-1].qVal[1])

  def.symbol("print") do (i: In):
    let a = i.peek
    a.print
  
  def.symbol("print!") do (i: In):
    i.pop.print

  def.symbol("fread") do (i: In):
    let vals = i.expect("string")
    let file = vals[0].strVal
    var contents = ""
    if MINCOMPILED:
      var compiledFile = strutils.replace(strutils.replace(file, "\\", "/"), "./", "")
      if COMPILEDASSETS.hasKey(compiledFile):
        contents = COMPILEDASSETS[compiledFile]
    if contents == "":
      contents = file.readFile
    i.push newVal(contents)
  
  def.symbol("fwrite") do (i: In):
    let vals = i.expect("string", "string")
    let a = vals[0]
    let b = vals[1]
    a.strVal.writeFile(b.strVal)
  
  def.symbol("fappend") do (i: In):
    let vals = i.expect("string", "string")
    let a = vals[0]
    let b = vals[1]
    var f:File
    discard f.open(a.strVal, fmAppend)
    f.write(b.strVal)
    f.close()

  def.finalize("io")
