# Adapted from: https://github.com/Araq/Nimrod/blob/v0.9.6/lib/pure/json.nim
import lexbase, strutils, streams, unicode, tables
import types

const
  errorMessages: array [MinParserError, string] = [
    "no error",
    "invalid token",
    "string expected",
    "')' expected",
    "'\"' or \"'\" expected",
    "'*/' expected",
    "EOF expected",
    "expression expected"
  ]
  tokToStr: array [MinTokenKind, string] = [
    "invalid token",
    "EOF",
    "string literal",
    "int literal",
    "float literal",
    "(", 
    ")",
    "symbol",
    "true",
    "false"
  ]

proc open*(my: var MinParser, input: Stream, filename: string) =
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = eMinError
  my.a = ""

proc close*(my: var MinParser) {.inline.} = 
  lexbase.close(my)

proc getInt*(my: MinParser): int {.inline.} = 
  assert(my.kind == eMinInt)
  return parseint(my.a)

proc getFloat*(my: MinParser): float {.inline.} = 
  assert(my.kind == eMinFloat)
  return parseFloat(my.a)

proc kind*(my: MinParser): MinEventKind {.inline.} = 
  return my.kind

proc getColumn*(my: MinParser): int {.inline.} = 
  result = getColNumber(my, my.bufpos)

proc getLine*(my: MinParser): int {.inline.} = 
  result = my.lineNumber

proc getFilename*(my: MinParser): string {.inline.} = 
  result = my.filename
  
proc errorMsg*(my: MinParser, msg: string): string = 
  assert(my.kind == eMinError)
  result = "$1 [l:$2, c:$3] ERROR - $4" % [
    my.filename, $getLine(my), $getColumn(my), msg]

proc errorMsg*(my: MinParser): string = 
  assert(my.kind == eMinError)
  result = errorMsg(my, errorMessages[my.err])
  
proc errorMsgExpected*(my: MinParser, e: string): string = 
  result = errorMsg(my, e & " expected")

proc raiseParseError*(p: MinParser, msg: string) {.noinline, noreturn.} =
  raise EMinParsingError(msg: errorMsgExpected(p, msg))

proc raiseUndefinedError*(p:MinParser, msg: string) {.noinline, noreturn.} =
  raise EMinUndefinedError(msg: errorMsg(p, msg))

#proc error(p: MinParser, msg: string) = 
#  writeln(stderr, p.errorMsg(msg))
#  flushFile(stderr)

proc parseNumber(my: var MinParser) = 
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] == '-': 
    add(my.a, '-')
    inc(pos)
  if buf[pos] == '.': 
    add(my.a, "0.")
    inc(pos)
  else:
    while buf[pos] in Digits:
      add(my.a, buf[pos])
      inc(pos)
    if buf[pos] == '.':
      add(my.a, '.')
      inc(pos)
  # digits after the dot:
  while buf[pos] in Digits:
    add(my.a, buf[pos])
    inc(pos)
  if buf[pos] in {'E', 'e'}:
    add(my.a, buf[pos])
    inc(pos)
    if buf[pos] in {'+', '-'}:
      add(my.a, buf[pos])
      inc(pos)
    while buf[pos] in Digits:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc handleHexChar(c: char, x: var int): bool = 
  result = true # Success
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else: result = false # error

proc parseString(my: var MinParser): MinTokenKind =
  result = tkString
  var pos = my.bufpos + 1
  var buf = my.buf
  while true:
    case buf[pos] 
    of '\0': 
      my.err = errQuoteExpected
      result = tkError
      break
    of '"':
      inc(pos)
      break
    of '\\':
      case buf[pos+1]
      of '\\', '"', '\'', '/': 
        add(my.a, buf[pos+1])
        inc(pos, 2)
      of 'b':
        add(my.a, '\b')
        inc(pos, 2)      
      of 'f':
        add(my.a, '\f')
        inc(pos, 2)      
      of 'n':
        add(my.a, '\L')
        inc(pos, 2)      
      of 'r':
        add(my.a, '\C')
        inc(pos, 2)    
      of 't':
        add(my.a, '\t')
        inc(pos, 2)
      of 'u':
        inc(pos, 2)
        var r: int
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        add(my.a, toUTF8(Rune(r)))
      else: 
        # don't bother with the error
        add(my.a, buf[pos])
        inc(pos)
    of '\c': 
      pos = lexbase.handleCR(my, pos)
      buf = my.buf
      add(my.a, '\c')
    of '\L': 
      pos = lexbase.handleLF(my, pos)
      buf = my.buf
      add(my.a, '\L')
    else:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos # store back

proc parseSymbol(my: var MinParser): MinTokenKind = 
  result = tkSymbol
  var pos = my.bufpos
  var buf = my.buf
  if not(buf[pos] in Whitespace):
    while not(buf[pos] in WhiteSpace) and not(buf[pos] in ['\0', ')', '(']):
        add(my.a, buf[pos])
        inc(pos)
  my.bufpos = pos

proc skip(my: var MinParser) = 
  var pos = my.bufpos
  var buf = my.buf
  while true: 
    case buf[pos]
    of ';':
      # skip line comment:
      inc(pos, 2)
      while true:
        case buf[pos] 
        of '\0': 
          break
        of '\c': 
          pos = lexbase.handleCR(my, pos)
          buf = my.buf
          break
        of '\L': 
          pos = lexbase.handleLF(my, pos)
          buf = my.buf
          break
        else:
          inc(pos)
    of '/': 
      if buf[pos+1] == '/': 
        # skip line comment:
        inc(pos, 2)
        while true:
          case buf[pos] 
          of '\0': 
            break
          of '\c': 
            pos = lexbase.handleCR(my, pos)
            buf = my.buf
            break
          of '\L': 
            pos = lexbase.handleLF(my, pos)
            buf = my.buf
            break
          else:
            inc(pos)
      elif buf[pos+1] == '*':
        # skip long comment:
        inc(pos, 2)
        while true:
          case buf[pos] 
          of '\0': 
            my.err = errEOC_Expected
            break
          of '\c': 
            pos = lexbase.handleCR(my, pos)
            buf = my.buf
          of '\L': 
            pos = lexbase.handleLF(my, pos)
            buf = my.buf
          of '*':
            inc(pos)
            if buf[pos] == '/': 
              inc(pos)
              break
          else:
            inc(pos)
      else: 
        break
    of ' ', '\t': 
      inc(pos)
    of '\c':  
      pos = lexbase.handleCR(my, pos)
      buf = my.buf
    of '\L': 
      pos = lexbase.handleLF(my, pos)
      buf = my.buf
    else:
      break
  my.bufpos = pos

proc getToken*(my: var MinParser): MinTokenKind =
  setLen(my.a, 0)
  skip(my) 
  case my.buf[my.bufpos]
  of '-', '.':
    if my.bufpos+1 <= my.buf.len and my.buf[my.bufpos+1] in '0'..'9':
      parseNumber(my)
      if {'.', 'e', 'E'} in my.a:
        result = tkFloat
      else:
        result = tkInt
    else:
      result = parseSymbol(my)
  of '0'..'9': 
    parseNumber(my)
    if {'.', 'e', 'E'} in my.a:
      result = tkFloat
    else:
      result = tkInt
  of '"':
    result = parseString(my)
  of '(':
    inc(my.bufpos)
    result = tkBracketLe
  of ')':
    inc(my.bufpos)
    result = tkBracketRi
  of '\0':
    result = tkEof
  else:
    result = parseSymbol(my)
    case my.a 
    of "true": result = tkTrue
    of "false": result = tkFalse
    else: 
      discard
  my.token = result


proc next*(my: var MinParser) = 
  var tk = getToken(my)
  var i = my.state.len-1
  case my.state[i]
  of stateEof:
    if tk == tkEof:
      my.kind = eMinEof
    else:
      my.kind = eMinError
      my.err = errEofExpected
  of stateStart: 
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse:
      my.state[i] = stateEof # expect EOF next!
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation) # we expect any
      my.kind = eMinQuotationStart
    of tkEof:
      my.kind = eMinEof
    else:
      my.kind = eMinError
      my.err = errEofExpected
  of stateQuotation:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse:
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation)
      my.kind = eMinQuotationStart
    of tkBracketRi:
      my.kind = eMinQuotationEnd
      discard my.state.pop()
    else:
      my.kind = eMinError
      my.err = errBracketRiExpected
  of stateExpectValue:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse:
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation)
      my.kind = eMinQuotationStart
    else:
      my.kind = eMinError
      my.err = errExprExpected

proc eat(p: var MinParser, token: MinTokenKind) = 
  if p.token == token: discard getToken(p)
  else: raiseParseError(p, tokToStr[token])

proc parseMinValue*(p: var MinParser): MinValue =
  #echo p.a, " (", p.token, ")"
  case p.token
  of tkTrue:
    result = MinValue(kind: minBool, boolVal: true, column: p.getColumn, line: p.lineNumber)
    discard getToken(p)
  of tkFalse:
    result = MinValue(kind: minBool, boolVal: false, column: p.getColumn, line: p.lineNumber)
    discard getToken(p)
  of tkString:
    result = MinValue(kind: minString, strVal: p.a, column: p.getColumn, line: p.lineNumber)
    p.a = ""
    discard getToken(p)
  of tkInt:
    result = MinValue(kind: minInt, intVal: parseint(p.a), column: p.getColumn, line: p.lineNumber)
    discard getToken(p)
  of tkFloat:
    result = MinValue(kind: minFloat, floatVal: parseFloat(p.a), column: p.getColumn, line: p.lineNumber)
    discard getToken(p)
  of tkBracketLe:
    var q = newSeq[MinValue](0)
    discard getToken(p)
    while p.token != tkBracketRi: 
      q.add parseMinValue(p)
    eat(p, tkBracketRi)
    result = MinValue(kind: minQuotation, qVal: q, column: p.getColumn, line: p.lineNumber)
  of tkSymbol:
    result = MinValue(kind: minSymbol, symVal: p.a, column: p.getColumn, line: p.lineNumber)
    p.a = ""
    discard getToken(p)
  else:
    raiseUndefinedError(p, "Undefined value: '"&p.a&"'")
  result.filename = p.filename

proc `$`*(a: MinValue): string =
  case a.kind:
    of minBool:
      return $a.boolVal
    of minSymbol:
      return a.symVal
    of minString:
      return "\""&a.strVal&"\""
    of minInt:
      return $a.intVal
    of minFloat:
      return $a.floatVal
    of minQuotation:
      var q = "("
      for i in a.qVal:
        q = q & $i & " "
      q = q.strip & ")"
      return q

proc `$$`*(a: MinValue): string =
  case a.kind:
    of minBool:
      return $a.boolVal
    of minSymbol:
      return a.symVal
    of minString:
      return a.strVal
    of minInt:
      return $a.intVal
    of minFloat:
      return $a.floatVal
    of minQuotation:
      var q = "("
      for i in a.qVal:
        q = q & $i & " "
      q = q.strip & ")"
      return q

proc print*(a: MinValue) =
  stdout.write($$a)

proc `==`*(a: MinValue, b: MinValue): bool =
  if a.kind == minInt and b.kind == minInt:
    return a.intVal == b.intVal
  elif a.kind == minInt and b.kind == minFloat:
    return a.intVal.float == b.intVal.float
  elif a.kind == minFloat and b.kind == minFloat:
    return a.floatVal == b.floatVal
  elif a.kind == minFloat and b.kind == minInt:
    return a.floatVal == b.intVal.float
  elif a.kind == b.kind:
    if a.kind == minString:
      return a.strVal == b.strVal
    elif a.kind == minBool:
      return a.boolVal == b.boolVal
    elif a.kind == minQuotation:
      if a.qVal.len == b.qVal.len:
        var c = 0
        for item in a.qVal:
          if item == b.qVal[c]:
            c.inc
          else:
            return false
        return true
      else:
        return false
  else:
    return false
