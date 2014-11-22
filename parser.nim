# Adapted from: https://github.com/Araq/Nimrod/blob/v0.9.6/lib/pure/min.nim
import lexbase, strutils, streams, unicode, tables

type 
  TMinTokenKind* = enum
    tkError,
    tkEof,
    tkString,
    tkInt,
    tkFloat,
    tkBracketLe,
    tkBracketRi,
    tkSymbol
  TMinKind* = enum
    minInt,
    minFloat,
    minQuotation,
    minString,
    minSymbol
  TMinValue* = object
    first*: int
    last*: int
    line*: int 
    case kind*: TMinKind
      of minInt: intVal*: BiggestInt
      of minFloat: floatVal*: BiggestFloat
      of minQuotation: qVal*: seq[TMinValue]
      of minString: strVal*: string
      of minSymbol: symVal*: string
  TMinEventKind* = enum    ## enumeration of all events that may occur when parsing
    eMinError,             ## an error ocurred during parsing
    eMinEof,               ## end of file reached
    eMinString,            ## a string literal
    eMinInt,               ## an integer literal
    eMinFloat,             ## a float literal
    eMinQuotationStart,    ## start of an array: the ``[`` token
    eMinQuotationEnd       ## start of an array: the ``]`` token
  TMinParserError* = enum        ## enumeration that lists all errors that can occur
    errNone,               ## no error
    errInvalidToken,       ## invalid token
    errStringExpected,     ## string expected
    errBracketRiExpected,  ## ``]`` expected
    errQuoteExpected,      ## ``"`` or ``'`` expected
    errEOC_Expected,       ## ``*/`` expected
    errEofExpected,        ## EOF expected
    errExprExpected
  TMinParserState = enum 
    stateEof, 
    stateStart, 
    stateQuotation, 
    stateExpectValue
  TMinParser* = object of TBaseLexer
    a*: string
    token*: TMinTokenKind
    state*: seq[TMinParserState]
    kind*: TMinEventKind
    err*: TMinParserError
    filename*: string
  TMinStack* = seq[TMinValue]
  EMinParsingError* = ref object of EInvalidValue 
  EMinUndefinedError* = ref object of EInvalidValue

const
  errorMessages: array [TMinParserError, string] = [
    "no error",
    "invalid token",
    "string expected",
    "']' expected",
    "'\"' or \"'\" expected",
    "'*/' expected",
    "EOF expected",
    "expression expected"
  ]
  tokToStr: array [TMinTokenKind, string] = [
    "invalid token",
    "EOF",
    "string literal",
    "int literal",
    "float literal",
    "[", 
    "]",
    "symbol"
  ]

proc open*(my: var TMinParser, input: PStream, filename: string) =
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = eMinError
  my.a = ""

proc close*(my: var TMinParser) {.inline.} = 
  lexbase.close(my)

proc getInt*(my: TMinParser): BiggestInt {.inline.} = 
  assert(my.kind == eMinInt)
  return parseBiggestInt(my.a)

proc getFloat*(my: TMinParser): float {.inline.} = 
  assert(my.kind == eMinFloat)
  return parseFloat(my.a)

proc kind*(my: TMinParser): TMinEventKind {.inline.} = 
  return my.kind

proc getColumn*(my: TMinParser): int {.inline.} = 
  result = getColNumber(my, my.bufpos)

proc getLine*(my: TMinParser): int {.inline.} = 
  result = my.lineNumber

proc getFilename*(my: TMinParser): string {.inline.} = 
  result = my.filename
  
proc errorMsg*(my: TMinParser, msg: string): string = 
  assert(my.kind == eMinError)
  result = "$1 [l:$2, c:$3] ERROR - $4" % [
    my.filename, $getLine(my), $getColumn(my), msg]

proc errorMsg*(my: TMinParser): string = 
  assert(my.kind == eMinError)
  result = errorMsg(my, errorMessages[my.err])
  
proc errorMsgExpected*(my: TMinParser, e: string): string = 
  result = errorMsg(my, e & " expected")

proc raiseParseError*(p: TMinParser, msg: string) {.noinline, noreturn.} =
  raise EMinParsingError(msg: errorMsgExpected(p, msg))

proc raiseUndefinedError*(p:TMinParser, msg: string) {.noinline, noreturn.} =
  raise EMinUndefinedError(msg: errorMsg(p, msg))

proc error(p: TMinParser, msg: string) = 
  writeln(stderr, p.errorMsg(msg))
  flushFile(stderr)

proc parseNumber(my: var TMinParser) = 
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

proc parseString(my: var TMinParser): TMinTokenKind =
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
        add(my.a, toUTF8(TRune(r)))
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

proc parseSymbol(my: var TMinParser): TMinTokenKind = 
  result = tkSymbol
  var pos = my.bufpos
  var buf = my.buf
  if not(buf[pos] in Whitespace):
    while not(buf[pos] in WhiteSpace) and not(buf[pos] in ['\0', ']', '[']):
        add(my.a, buf[pos])
        inc(pos)
  my.bufpos = pos

proc skip(my: var TMinParser) = 
  var pos = my.bufpos
  var buf = my.buf
  while true: 
    case buf[pos]
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

proc getToken*(my: var TMinParser): TMinTokenKind =
  setLen(my.a, 0)
  skip(my) 
  case my.buf[my.bufpos]
  of '-', '.', '0'..'9': 
    parseNumber(my)
    if {'.', 'e', 'E'} in my.a:
      result = tkFloat
    else:
      result = tkInt
  of '"':
    result = parseString(my)
  of '[':
    inc(my.bufpos)
    result = tkBracketLe
  of ']':
    inc(my.bufpos)
    result = tkBracketRi
  of '\0':
    result = tkEof
  else: 
    result = parseSymbol(my)
  my.token = result


proc next*(my: var TMinParser) = 
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
    of tkString, tkInt, tkFloat:
      my.state[i] = stateEof # expect EOF next!
      my.kind = TMinEventKind(ord(tk))
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
    of tkString, tkInt, tkFloat:
      my.kind = TMinEventKind(ord(tk))
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
    of tkString, tkInt, tkFloat:
      my.kind = TMinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation)
      my.kind = eMinQuotationStart
    else:
      my.kind = eMinError
      my.err = errExprExpected

proc eat(p: var TMinParser, token: TMinTokenKind) = 
  if p.token == token: discard getToken(p)
  else: raiseParseError(p, tokToStr[token])

proc parseMinValue*(p: var TMinParser): TMinValue =
  #echo p.a, " (", p.token, ")"
  case p.token
  of tkString:
    result = TMinValue(kind: minString, strVal: p.a, first: p.bufpos-p.a.len, last: p.bufpos, line: p.lineNumber)
    p.a = ""
    discard getToken(p)
  of tkInt:
    result = TMinValue(kind: minInt, intVal: parseBiggestInt(p.a), first: p.bufpos-p.a.len, last: p.bufpos, line: p.lineNumber)
    discard getToken(p)
  of tkFloat:
    result = TMinValue(kind: minFloat, floatVal: parseFloat(p.a), first: p.bufpos-p.a.len, last: p.bufpos, line: p.lineNumber)
    discard getToken(p)
  of tkBracketLe:
    var q = newSeq[TMinValue](0)
    discard getToken(p)
    while p.token != tkBracketRi: 
      q.add parseMinValue(p)
    eat(p, tkBracketRi)
    result = TMinValue(kind: minQuotation, qVal: q, first: p.bufpos-p.a.len, last: p.bufpos, line: p.lineNumber)
  of tkSymbol:
    result = TMinValue(kind: minSymbol, symVal: p.a, first: p.bufpos-p.a.len, last: p.bufpos, line: p.lineNumber)
    p.a = ""
    discard getToken(p)
  else:
    raiseUndefinedError(p, "Undefined value: '"&p.a&"'")

