# Adapted from: https://github.com/Araq/Nimrod/blob/v0.9.6/lib/pure/json.nim
import 
  lexbase, 
  sequtils,
  strutils, 
  streams, 
  unicode, 
  tables,
  json,
  critbits,
  math,
  logging

type
  MinTokenKind* = enum
    tkError,
    tkEof,
    tkString,
    tkInt,
    tkFloat,
    tkBracketLe,
    tkBracketRi,
    tkBraceLe,
    tkBraceRi,
    tkSymbol,
    tkNil,
    tkTrue,
    tkFalse
  MinEventKind* = enum     ## enumeration of all events that may occur when parsing
    eMinError,             ## an error ocurred during parsing
    eMinEof,               ## end of file reached
    eMinString,            ## a string literal
    eMinInt,               ## an integer literal
    eMinFloat,             ## a float literal
    eMinQuotationStart,    ## start of an array: the ``(`` token
    eMinQuotationEnd,      ## start of an array: the ``)`` token
    eMinDictionaryStart,   ## start of a dictionary: the ``{`` token
    eMinDictionaryEnd      ## start of a dictionary: the ``}`` token
  MinParserError* = enum        ## enumeration that lists all errors that can occur
    errNone,               ## no error
    errInvalidToken,       ## invalid token
    errStringExpected,     ## string expected
    errBracketRiExpected,  ## ``)`` expected
    errBraceRiExpected,    ## ``}`` expected
    errQuoteExpected,      ## ``"`` or ``'`` expected
    errEOC_Expected,       ## ``*/`` expected
    errEofExpected,        ## EOF expected
    errExprExpected
  MinParserState* = enum 
    stateEof, 
    stateStart, 
    stateQuotation, 
    stateDictionary, 
    stateExpectValue
  MinParser* = object of BaseLexer
    a*: string
    token*: MinTokenKind
    state*: seq[MinParserState]
    kind*: MinEventKind
    err*: MinParserError
    filename*: string
  MinValue* = JsonNode 
  MinScope* {.acyclic.} = object
    line*: int
    column*: int
    filename*: string
    symbols*: CritBitTree[MinOperator]
    sigils*: CritBitTree[MinOperator]
    obj*: pointer # Used only for dicts
    objType*: string # Used only for dicts
    parent*: ref MinScope
    name*: string
    val*: MinValue
  MinOperatorProc* = proc (i: In) {.closure.}
  MinOperatorKind* = enum
    minProcOp
    minValOp
  MinOperator* = object
    sealed*: bool
    case kind*: MinOperatorKind
    of minProcOp:
      prc*: MinOperatorProc
    of minValOp:
      val*: MinValue
  MinStack* = seq[MinValue]
  In* = var MinInterpreter
  MinInterpreter* = object
    stack*: MinStack
    trace*: MinStack
    stackcopy*: MinStack
    pwd*: string
    scope*: ref MinScope
    parser*: MinParser
    currSym*: MinValue
    filename*: string
    evaluating*: bool 
  MinParsingError* = ref object of ValueError 
  MinUndefinedError* = ref object of ValueError
  MinEmptyStackError* = ref object of ValueError
  MinInvalidError* = ref object of ValueError
  MinOutOfBoundsError* = ref object of ValueError

# Helpers

proc raiseInvalid*(msg: string) {.extern:"min_exported_symbol_$1".}=
  raise MinInvalidError(msg: msg)

proc raiseUndefined*(msg: string) {.extern:"min_exported_symbol_$1".}=
  raise MinUndefinedError(msg: msg)

proc raiseOutOfBounds*(msg: string) {.extern:"min_exported_symbol_$1".}=
  raise MinOutOfBoundsError(msg: msg)

proc raiseEmptyStack*() {.extern:"min_exported_symbol_$1".}=
  raise MinEmptyStackError(msg: "Insufficient items on the stack")

const
  errorMessages: array[MinParserError, string] = [
    "no error",
    "invalid token",
    "string expected",
    "')' expected",
    "'}' expected",
    "'\"' or \"'\" expected",
    "'*/' expected",
    "EOF expected",
    "expression expected"
  ]
  tokToStr: array[MinTokenKind, string] = [
    "invalid token",
    "EOF",
    "string literal",
    "int literal",
    "float literal",
    "(", 
    ")",
    "{",
    "}",
    "symbol",
    "nil",
    "true",
    "false"
  ]

proc newScope*(parent: ref MinScope): MinScope {.extern:"min_exported_symbol_$1".}=
  result = MinScope(parent: parent)

proc newScopeRef*(parent: ref MinScope): ref MinScope {.extern:"min_exported_symbol_$1".}=
  new(result)
  result[] = newScope(parent)

proc open*(my: var MinParser, input: Stream, filename: string) {.extern:"min_exported_symbol_$1".}=
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = eMinError
  my.a = ""

proc close*(my: var MinParser) {.inline, extern:"min_exported_symbol_$1".}= 
  lexbase.close(my)

proc getInt*(my: MinParser): int {.inline, extern:"min_exported_symbol_$1".}= 
  assert(my.kind == eMinInt)
  return parseint(my.a)

proc getFloat*(my: MinParser): float {.inline, extern:"min_exported_symbol_$1".}= 
  assert(my.kind == eMinFloat)
  return parseFloat(my.a)

proc kind*(my: MinParser): MinEventKind {.inline, extern:"min_exported_symbol_$1".}= 
  return my.kind

proc getColumn*(my: MinParser): int {.inline, extern:"min_exported_symbol_$1".}= 
  result = getColNumber(my, my.bufpos)

proc getLine*(my: MinParser): int {.inline, extern:"min_exported_symbol_$1".}= 
  result = my.lineNumber

proc getFilename*(my: MinParser): string {.inline, extern:"min_exported_symbol_$1".}= 
  result = my.filename
  
proc errorMsg*(my: MinParser, msg: string): string {.extern:"min_exported_symbol_$1".}= 
  assert(my.kind == eMinError)
  result = "$1 [l:$2, c:$3] ERROR - $4" % [
    my.filename, $getLine(my), $getColumn(my), msg]

proc errorMsg*(my: MinParser): string {.extern:"min_exported_symbol_$1_2".}= 
  assert(my.kind == eMinError)
  result = errorMsg(my, errorMessages[my.err])
  
proc errorMsgExpected*(my: MinParser, e: string): string {.extern:"min_exported_symbol_$1".}= 
  result = errorMsg(my, e & " expected")

proc raiseParsing*(p: MinParser, msg: string) {.noinline, noreturn, extern:"min_exported_symbol_$1".}=
  raise MinParsingError(msg: errorMsgExpected(p, msg))

proc raiseUndefined*(p:MinParser, msg: string) {.noinline, noreturn, extern:"min_exported_symbol_$1_2".}=
  raise MinUndefinedError(msg: errorMsg(p, msg))

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
    while not(buf[pos] in WhiteSpace) and not(buf[pos] in ['\0', ')', '(', '}', '{']):
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

proc getToken*(my: var MinParser): MinTokenKind {.extern:"min_exported_symbol_$1".}=
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
  of '{':
    inc(my.bufpos)
    result = tkBraceLe
  of '}':
    inc(my.bufpos)
    result = tkBraceRi
  of '\0':
    result = tkEof
  else:
    result = parseSymbol(my)
    case my.a 
    of "nil": result = tkNil
    of "true": result = tkTrue
    of "false": result = tkFalse
    else: 
      discard
  my.token = result


proc next*(my: var MinParser) {.extern:"min_exported_symbol_$1".}= 
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
    of tkString, tkInt, tkFloat, tkNil, tkTrue, tkFalse:
      my.state[i] = stateEof # expect EOF next!
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation) # we expect any
      my.kind = eMinQuotationStart
    of tkBraceLe: 
      my.state.add(stateDictionary) # we expect any
      my.kind = eMinDictionaryStart
    of tkEof:
      my.kind = eMinEof
    else:
      my.kind = eMinError
      my.err = errEofExpected
  of stateQuotation:
    case tk
    of tkString, tkInt, tkFloat, tkNil, tkTrue, tkFalse:
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation)
      my.kind = eMinQuotationStart
    of tkBraceLe: 
      my.state.add(stateDictionary)
      my.kind = eMinDictionaryStart
    of tkBracketRi:
      my.kind = eMinQuotationEnd
      discard my.state.pop()
    of tkBraceRi:
      my.kind = eMinDictionaryEnd
      discard my.state.pop()
    else:
      my.kind = eMinError
      my.err = errBracketRiExpected
  of stateDictionary:
    case tk
    of tkString, tkInt, tkFloat, tkNil, tkTrue, tkFalse:
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation)
      my.kind = eMinQuotationStart
    of tkBraceLe: 
      my.state.add(stateDictionary)
      my.kind = eMinDictionaryStart
    of tkBracketRi:
      my.kind = eMinQuotationEnd
      discard my.state.pop()
    of tkBraceRi:
      my.kind = eMinDictionaryEnd
      discard my.state.pop()
    else:
      my.kind = eMinError
      my.err = errBraceRiExpected
  of stateExpectValue:
    case tk
    of tkString, tkInt, tkFloat, tkNil, tkTrue, tkFalse:
      my.kind = MinEventKind(ord(tk))
    of tkBracketLe: 
      my.state.add(stateQuotation)
      my.kind = eMinQuotationStart
    of tkBraceLe: 
      my.state.add(stateDictionary)
      my.kind = eMinDictionaryStart
    else:
      my.kind = eMinError
      my.err = errExprExpected

proc eat(p: var MinParser, token: MinTokenKind) {.extern:"min_exported_symbol_$1".}= 
  if p.token == token: discard getToken(p)
  else: raiseParsing(p, tokToStr[token])

proc parseMinValue*(p: var MinParser, i: In): MinValue {.extern:"min_exported_symbol_$1".}=
  #echo p.a, " (", p.token, ")"
  case p.token
  of tkNil:
    result = newJNull()
  of tkTrue:
    result = %true
    discard getToken(p)
  of tkFalse:
    result = %false
    discard getToken(p)
  of tkString:
    result = %p.a
    p.a = ""
    discard getToken(p)
  of tkInt:
    result = %parseInt(p.a)
    discard getToken(p)
  of tkFloat:
    result = %parseFloat(p.a)
    discard getToken(p)
  of tkBracketLe:
    var q = newJArray()
    var oldscope = i.scope
    var newscope = newScopeRef(i.scope)
    i.scope = newscope
    discard getToken(p)
    while p.token != tkBracketRi: 
      q.add p.parseMinValue(i)
    eat(p, tkBracketRi)
    i.scope.val = q
    i.scope.line = p.lineNumber
    i.scope.column = p.getColumn
    i.scope.filename = p.filename
    i.scope = oldscope
    result = q
  of tkBraceLe:
    var q = newJObject()
    q[";raw"] = newJArray()
    var oldscope = i.scope
    var newscope = newScopeRef(i.scope)
    i.scope = newscope
    discard getToken(p)
    while p.token != tkBraceRi: 
      q[";raw"].add p.parseMinValue(i)
    eat(p, tkBraceRi)
    i.scope.line = p.lineNumber
    i.scope.column = p.getColumn
    i.scope.filename = p.filename
    i.scope = oldscope
    result = q
  of tkSymbol:
    result = newJObject()
    result.add(";symbol", %p.a)
    result.add("line", %p.lineNumber)
    result.add("column", %p.getColumn)
    result.add("filename", %p.filename)
    p.a = ""
    discard getToken(p)
  else:
    raiseUndefined(p, "Undefined value: '"&p.a&"'")

# Predicates

proc isSymbol*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == JObject and s.hasKey(";symbol")

proc isRawDictionary*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == JObject and s.hasKey(";raw")

proc isQuotation*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}= 
  return s.kind == JArray

proc isString*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}= 
  return s.kind == JString

proc isFloat*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == JFloat

proc isInt*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == JInt

proc isNumber*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == JInt or s.kind == JFloat

proc isBool*(s: MinValue): bool =
  return s.kind == JBool

proc isStringLike*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.isSymbol or s.isString or (s.isQuotation and s.elems.len == 1 and s.elems[0].isSymbol)

proc isDictionary*(q: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return q.kind == JObject and not q.hasKey(";symbol")

proc isTypedDictionary*(q: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  if q.isDictionary:
    return 
  return false

proc isTypedDictionary*(q: MinValue, t: string): bool {.extern:"min_exported_symbol_$1_2".}=
  if q.isTypedDictionary:
    return q.hasKey(";type")
  return false

proc `$`*(a: MinValue): string {.extern:"min_exported_symbol_$1".}=
  case a.kind:
    of JObject:
      if (a.hasKey(";symbol")):
        return a[";symbol"].getstr
      else:
        # TODO: Handle typed dictionaries
        var d = "{"
        for key, val in a.pairs:
          d &= $val & " " & $key & ":"
        #if not a.objType.isNil: 
        #  d &= ";" & a.objType
        #d = d.strip & "}"
        return d
    of JArray:
      var q = "("
      for i in a.elems:
        q = q & $i & " "
      q = q.strip & ")"
      return q
    else:
      return $a

proc str*(a: MinValue): string {.extern:"min_exported_symbol_$1".} =
  return $a

proc `$$`*(a: MinValue): string {.extern:"min_exported_symbol_$1".}=
  case a.kind:
    of JObject:
      if (a.isSymbol):
        return a[";symbol"].getstr
      else:
        # TODO: Handle typed dictionaries
        var d = "{"
        for key, val in a.pairs:
          d &= $val & " " & $key & ":"
        #if not a.objType.isNil: 
        #  d &= ";" & a.objType
        #d = d.strip & "}"
        return d
    of JArray:
      var q = "("
      for i in a.elems:
        q = q & $i & " "
      q = q.strip & ")"
      return q
    of JString:
      return a.getStr
    else:
      return $a
  

proc print*(a: MinValue) {.extern:"min_exported_symbol_$1".}=
  stdout.write($$a)

