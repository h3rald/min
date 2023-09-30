# Adapted from: https://github.com/Araq/Nimrod/blob/v0.9.6/lib/pure/json.nim
import
  std/[lexbase,
  strutils,
  sequtils,
  streams,
  critbits,
  json]

import
  baseutils

import std/unicode except strip

type
  MinTokenKind* = enum
    tkError,
    tkEof,
    tkString,
    tkCommand,
    tkInt,
    tkFloat,
    tkBracketLe,
    tkBracketRi,
    tkSqBracketLe,
    tkSqBracketRi,
    tkBraceLe,
    tkBraceRi,
    tkSymbol,
    tkNull,
    tkTrue,
    tkFalse
  MinKind* = enum
    minInt,
    minFloat,
    minQuotation,
    minCommand,
    minDictionary,
    minString,
    minSymbol,
    minNull,
    minBool
  MinEventKind* = enum   ## enumeration of all events that may occur when parsing
    eMinError,           ## an error ocurred during parsing
    eMinEof,             ## end of file reached
    eMinString,          ## a string literal
    eMinInt,             ## an integer literal
    eMinFloat,           ## a float literal
    eMinQuotationStart,  ## start of an array: the ``(`` token
    eMinQuotationEnd,    ## start of an array: the ``)`` token
    eMinDictionaryStart, ## start of a dictionary: the ``{`` token
    eMinDictionaryEnd    ## start of a dictionary: the ``}`` token
  MinParserError* = enum    ## enumeration that lists all errors that can occur
    errNone,                ## no error
    errInvalidToken,        ## invalid token
    errStringExpected,      ## string expected
    errBracketRiExpected,   ## ``)`` expected
    errBraceRiExpected,     ## ``}`` expected
    errQuoteExpected,       ## ``"`` or ``'`` expected
    errSqBracketRiExpected, ## ``]`` expected
    errEOC_Expected,        ## ``*/`` expected
    errEofExpected,         ## EOF expected
    errExprExpected
  MinParserState* = enum
    stateEof,
    stateStart,
    stateQuotation,
    stateDictionary,
    stateExpectValue
  MinParser* = object of BaseLexer
    a*: string
    doc*: bool
    currSym*: MinValue
    token*: MinTokenKind
    state*: seq[MinParserState]
    kind*: MinEventKind
    err*: MinParserError
    filename*: string
  MinValue* = ref MinValueObject
  MinValueObject* {.acyclic, final.} = object
    line*: int
    column*: int
    filename*: string
    outerSym*: string
    docComment*: string
    case kind*: MinKind
      of minNull: discard
      of minInt: intVal*: BiggestInt
      of minFloat: floatVal*: BiggestFloat
      of minCommand: cmdVal*: string
      of minDictionary:
        scope*: ref MinScope
        obj*: pointer
        objType*: string
      of minQuotation:
        qVal*: seq[MinValue]
      of minString: strVal*: string
      of minSymbol: symVal*: string
      of minBool: boolVal*: bool
  MinScopeKind* = enum
    minNativeScope,
    minLangScope
  MinScope* {.acyclic, shallow, final.} = object
    parent*: ref MinScope
    symbols*: CritBitTree[MinOperator]
    sigils*: CritBitTree[MinOperator]
    kind*: MinScopeKind
  MinOperatorProc* = proc (i: In) {.closure.}
  MinOperatorKind* = enum
    minProcOp
    minValOp
  MinOperator* = object
    sealed*: bool
    doc*: JsonNode
    case kind*: MinOperatorKind
    of minProcOp:
      prc*: MinOperatorProc
    of minValOp:
      quotation*: bool
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
  MinNumBase* = enum
    baseDec = "dec"
    baseOct = "oct"
    baseBin = "bin"
    baseHex = "hex"

var CVARCOUNT = 0
var NUMBASE*: MinNumBase = baseDec

# Helpers

proc raiseInvalid*(msg: string) =
  raise MinInvalidError(msg: msg)

proc raiseUndefined*(msg: string) =
  raise MinUndefinedError(msg: msg)

proc raiseOutOfBounds*(msg: string) =
  raise MinOutOfBoundsError(msg: msg)

proc raiseEmptyStack*() =
  raise MinEmptyStackError(msg: "Insufficient items on the stack")

proc dVal*(v: MinValue): CritBitTree[MinOperator] {.inline,
    extern: "min_exported_symbol_$1".} =
  if v.kind != minDictionary:
    raiseInvalid("dVal - Dictionary expected, got " & $v.kind)
  if v.scope.isNil:
    return CritBitTree[MinOperator]()
  return v.scope.symbols

const
  errorMessages: array[MinParserError, string] = [
    "no error",
    "invalid token",
    "string expected",
    "')' expected",
    "'}' expected",
    "'\"' expected",
    "']' expected",
    "'*/' expected",
    "EOF expected",
    "expression expected"
  ]
  tokToStr: array[MinTokenKind, string] = [
    "invalid token",
    "EOF",
    "string literal",
    "command literal",
    "int literal",
    "float literal",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    "symbol",
    "null",
    "true",
    "false"
  ]

proc newScope*(parent: ref MinScope, kind = minLangScope): MinScope =
  result = MinScope(parent: parent, kind: kind)

proc newScopeRef*(parent: ref MinScope, kind = minLangScope): ref MinScope =
  new(result)
  result[] = newScope(parent, kind)

proc open*(my: var MinParser, input: Stream, filename: string) =
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = eMinError
  my.a = ""

proc close*(my: var MinParser) {.inline, extern: "min_exported_symbol_$1".} =
  lexbase.close(my)

proc getInt*(my: MinParser): int {.inline, extern: "min_exported_symbol_$1".} =
  assert(my.kind == eMinInt)
  return parseint(my.a)

proc getFloat*(my: MinParser): float {.inline,
    extern: "min_exported_symbol_$1".} =
  assert(my.kind == eMinFloat)
  return parseFloat(my.a)

proc kind*(my: MinParser): MinEventKind {.inline,
    extern: "min_exported_symbol_$1".} =
  return my.kind

proc getColumn*(my: MinParser): int {.inline,
    extern: "min_exported_symbol_$1".} =
  result = getColNumber(my, my.bufpos)

proc getLine*(my: MinParser): int {.inline, extern: "min_exported_symbol_$1".} =
  result = my.lineNumber

proc getFilename*(my: MinParser): string {.inline,
    extern: "min_exported_symbol_$1".} =
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

proc raiseParsing*(p: MinParser, msg: string) {.noinline, noreturn,
    extern: "min_exported_symbol_$1".} =
  raise MinParsingError(msg: errorMsgExpected(p, msg))

proc raiseUndefined*(p: MinParser, msg: string) {.noinline, noreturn,
    extern: "min_exported_symbol_$1_2".} =
  raise MinUndefinedError(msg: errorMsg(p, msg))

proc parseNumber(my: var MinParser) =
  var pos = my.bufpos
  var buf = my.buf
  var base = 'd'
  if buf[pos] == '-':
    add(my.a, '-')
    inc(pos)
  if buf[pos] == '0':
    add(my.a, buf[pos])
    inc(pos)
    if buf[pos] in {'o', 'b', 'x'}:
      base = buf[pos]
      add(my.a, buf[pos])
      inc(pos)
      if base == 'b':
        while buf[pos] in {'0', '1'}:
          add(my.a, buf[pos])
          inc(pos)
      elif base == 'o':
        while buf[pos] in {'0', '1', '2', '3', '4', '5', '6', '7'}:
          add(my.a, buf[pos])
          inc(pos)
      elif base == 'x':
        while buf[pos] in HexDigits:
          add(my.a, buf[pos])
          inc(pos)
  else:
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

proc parseCommand(my: var MinParser): MinTokenKind =
  result = tkCommand
  var pos = my.bufpos + 1
  var buf = my.buf
  while true:
    case buf[pos]
    of '\0':
      my.err = errSqBracketRiExpected
      result = tkError
      break
    of ']':
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
    while not(buf[pos] in WhiteSpace) and not(buf[pos] in ['\0', ')', '(', '}',
        '{', '[', ']']):
      if buf[pos] == '"':
        add(my.a, buf[pos])
        my.bufpos = pos
        let r = parseString(my)
        if r == tkError:
          result = tkError
          return
        add(my.a, buf[pos])
        return
      else:
        add(my.a, buf[pos])
        inc(pos)
  my.bufpos = pos

proc addDoc(my: var MinParser, docComment: string, reset = true) =
  if my.doc and not my.currSym.isNil and my.currSym.kind == minSymbol:
    if reset:
      my.doc = false
    if my.currSym.docComment.len == 0 or my.currSym.docComment.len > 0 and
        my.currSym.docComment[my.currSym.docComment.len-1] == '\n':
      my.currSym.docComment &= docComment.strip(true, false)
    else:
      my.currSym.docComment &= docComment

proc skip(my: var MinParser) =
  var pos = my.bufpos
  var buf = my.buf
  while true:
    case buf[pos]
    of ';':
      # skip line comment:
      if buf[pos+1] == ';':
        my.doc = true
      inc(pos, 2)
      while true:
        case buf[pos]
        of '\0':
          break
        of '\c':
          pos = lexbase.handleCR(my, pos)
          buf = my.buf
          my.addDoc "\n"
          break
        of '\L':
          pos = lexbase.handleLF(my, pos)
          buf = my.buf
          my.addDoc "\n"
          break
        else:
          my.addDoc $my.buf[pos], false
          inc(pos)
    of '#':
      if buf[pos+1] == '|':
        # skip long comment:
        if buf[pos+2] == '|':
          inc(pos)
          my.doc = true
        inc(pos, 2)
        while true:
          case buf[pos]
          of '\0':
            my.err = errEOC_Expected
            break
          of '\c':
            pos = lexbase.handleCR(my, pos)
            my.addDoc "\n", false
            buf = my.buf
          of '\L':
            pos = lexbase.handleLF(my, pos)
            my.addDoc "\n", false
            buf = my.buf
          of '|':
            inc(pos)
            if buf[pos] == '|':
              inc(pos)
            if buf[pos] == '#':
              inc(pos)
              break
            my.addDoc $buf[pos], false
          else:
            my.addDoc $my.buf[pos], false
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
  of '[':
    result = parseCommand(my)
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
    of "null": result = tkNull
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
    of tkString, tkInt, tkFloat, tkTrue, tkFalse:
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
    of tkString, tkInt, tkFloat, tkTrue, tkFalse:
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
    of tkString, tkInt, tkFloat, tkTrue, tkFalse:
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

proc eat(p: var MinParser, token: MinTokenKind) =
  if p.token == token: discard getToken(p)
  else: raiseParsing(p, tokToStr[token])

proc `$`*(a: MinValue): string {.inline, extern: "min_exported_symbol_$1".} =
  case a.kind:
    of minNull:
      return "null"
    of minBool:
      return $a.boolVal
    of minSymbol:
      return a.symVal
    of minString:
      return "\""&a.strVal.escapeJsonUnquoted&"\""
    of minInt:
      case NUMBASE
      of baseDec:
        return $a.intVal
      of baseOct:
        return "0o" & a.intVal.toOct(sizeof(a))
      of baseBin:
        return "0b" & a.intVal.toBin(sizeof(a))
      of baseHex:
        return "0x" & a.intVal.toHex(sizeof(a))
    of minFloat:
      return $a.floatVal
    of minQuotation:
      var q = "("
      for i in a.qVal:
        q = q & $i & " "
      q = q.strip & ")"
      return q
    of minDictionary:
      var d = "{"
      for i in a.dVal.pairs:
        var v = ""
        if i.val.kind == minProcOp:
          v = "<native>"
        else:
          v = $i.val.val
        var k = $i.key
        if k.contains(" "):
          k = "\"$1\"" % k
        d = d & v & " :" & k & " "
      if a.objType != "":
        d = d & ";" & a.objType
      d = d.strip & "}"
      return d
    of minCommand:
      return "[" & a.cmdVal & "]"

proc `$$`*(a: MinValue): string {.inline, extern: "min_exported_symbol_$1".} =
  case a.kind:
    of minNull:
      return "null"
    of minBool:
      return $a.boolVal
    of minSymbol:
      return a.symVal
    of minString:
      return a.strVal
    of minInt:
      case NUMBASE
      of baseDec:
        return $a.intVal
      of baseOct:
        return "0o" & a.intVal.toOct(sizeof(a))
      of baseBin:
        return "0b" & a.intVal.toBin(sizeof(a))
      of baseHex:
        return "0x" & a.intVal.toHex(sizeof(a))
    of minFloat:
      return $a.floatVal
    of minQuotation:
      var q = "("
      for i in a.qVal:
        q = q & $i & " "
      q = q.strip & ")"
      return q
    of minCommand:
      return "[" & a.cmdVal & "]"
    of minDictionary:
      var d = "{"
      for i in a.dVal.pairs:
        var v = ""
        if i.val.kind == minProcOp:
          v = "<native>"
        else:
          v = $i.val.val
        var k = $i.key
        if k.contains(" "):
          k = "\"$1\"" % k
        d = d & v & " :" & k & " "
      if a.objType != "":
        d = d & ";" & a.objType
      d = d.strip & "}"
      return d

proc parseMinValue*(p: var MinParser, i: In): MinValue =
  case p.token
  of tkNull:
    result = MinValue(kind: minNull)
    discard getToken(p)
  of tkTrue:
    result = MinValue(kind: minBool, boolVal: true)
    discard getToken(p)
  of tkFalse:
    result = MinValue(kind: minBool, boolVal: false)
    discard getToken(p)
  of tkString:
    result = MinValue(kind: minString, strVal: p.a)
    p.a = ""
    discard getToken(p)
  of tkCommand:
    result = MinValue(kind: minCommand, cmdVal: p.a)
    p.a = ""
    discard getToken(p)
  of tkInt:
    var baseIndex = 1
    var minLen = 2
    if p.a[0] == '-':
      baseIndex = 2
      minLen = 3
    if p.a.len > minLen and p.a[baseIndex] in {'b', 'o', 'x'}:
      case p.a[baseIndex]
      of 'o':
        result = MinValue(kind: minInt, intVal: parseOctInt(p.a))
      of 'b':
        result = MinValue(kind: minInt, intVal: parseBinInt(p.a))
      of 'x':
        result = MinValue(kind: minInt, intVal: parseHexInt(p.a))
      else:
        result = MinValue(kind: minInt, intVal: parseInt(p.a))
    else:
      result = MinValue(kind: minInt, intVal: parseInt(p.a))
    discard getToken(p)
  of tkFloat:
    result = MinValue(kind: minFloat, floatVal: parseFloat(p.a))
    discard getToken(p)
  of tkBracketLe:
    var q = newSeq[MinValue](0)
    discard getToken(p)
    while p.token != tkBracketRi:
      q.add p.parseMinValue(i)
    eat(p, tkBracketRi)
    result = MinValue(kind: minQuotation, qVal: q)
  of tkBraceLe:
    var scope = newScopeRef(nil)
    var val: MinValue
    discard getToken(p)
    var c = 0
    while p.token != tkBraceRi:
      c = c+1
      let v = p.parseMinValue(i)
      if val.isNil:
        val = v
      elif v.kind == minSymbol:
        let key = v.symVal
        if key[0] == ':':
          var offset = 0
          if key[1] == '"':
            offset = 1
          scope.symbols[key[1+offset .. key.len-1-offset]] = MinOperator(
              kind: minValOp, val: val, sealed: false)
          val = nil
        else:
          raiseInvalid("Invalid dictionary key: " & key)
      else:
        raiseInvalid("Invalid dictionary key: " & $v)
    eat(p, tkBraceRi)
    if c mod 2 != 0:
      raiseInvalid("Invalid dictionary")
    result = MinValue(kind: minDictionary, scope: scope)
  of tkSymbol:
    result = MinValue(kind: minSymbol, symVal: p.a, column: p.getColumn,
        line: p.lineNumber, filename: p.filename)
    p.a = ""
    p.currSym = result
    discard getToken(p)
  else:
    let err = "Undefined or invalid value: "&p.a
    raiseUndefined(p, err)
  result.filename = p.filename

proc compileMinValue*(p: var MinParser, i: In, push = true, indent = ""): seq[string] =
  var op = indent
  if push:
    op = indent&"i.push "
  result = newSeq[string](0)
  case p.token
  of tkNull:
    result = @[op&"MinValue(kind: minNull)"]
    discard getToken(p)
  of tkTrue:
    result = @[op&"MinValue(kind: minBool, boolVal: true)"]
    discard getToken(p)
  of tkFalse:
    result = @[op&"MinValue(kind: minBool, boolVal: false)"]
    discard getToken(p)
  of tkString:
    result = @[op&"MinValue(kind: minString, strVal: "&p.a.escapeEx&")"]
    p.a = ""
    discard getToken(p)
  of tkInt:
    result = @[op&"MinValue(kind: minInt, intVal: "&p.a&")"]
    discard getToken(p)
  of tkFloat:
    result = @[op&"MinValue(kind: minFloat, floatVal: "&p.a&")"]
    discard getToken(p)
  of tkBracketLe:
    CVARCOUNT.inc
    var qvar = "q" & $CVARCOUNT
    result.add indent&"var "&qvar&" = newSeq[MinValue](0)"
    discard getToken(p)
    while p.token != tkBracketRi:
      var instructions = p.compileMinValue(i, false, indent)
      let v = instructions.pop
      result = result.concat(instructions)
      result.add indent&qvar&".add "&v
    eat(p, tkBracketRi)
    result.add op&"MinValue(kind: minQuotation, qVal: "&qvar&")"
  of tkSqBracketLe, tkSqBracketRi:
    discard getToken(p)
  of tkCommand:
    result = @[op&"MinValue(kind: minCommand, cmdVal: "&p.a.escapeEx&")"]
    discard getToken(p)
  of tkBraceLe:
    result = newSeq[string](0)
    var val: MinValue
    discard getToken(p)
    var c = 0
    var valInitialized = false
    CVARCOUNT.inc
    var scopevar = "scope" & $CVARCOUNT
    CVARCOUNT.inc
    var valvar = "val" & $CVARCOUNT
    while p.token != tkBraceRi:
      c = c+1
      var instructions = p.compileMinValue(i, false, indent)
      let v = p.parseMinValue(i)
      let vs = instructions.pop
      result = result.concat(instructions)
      if val.isNil:
        if not valInitialized:
          result.add indent&"var "&valvar&": MinValue"
          valInitialized = true
        result.add indent&valvar&" = "&vs
      elif v.kind == minSymbol:
        let key = v.symVal
        if key[0] == ':':
          result.add indent&scopevar&".symbols["&key[1 ..
              key.len-1]&"] = MinOperator(kind: minValOp, val: "&valvar&", sealed: false)"
          val = nil
        else:
          raiseInvalid("Invalid dictionary key: " & key)
      else:
        raiseInvalid("Invalid dictionary key: " & $v)
    eat(p, tkBraceRi)
    if c mod 2 != 0:
      raiseInvalid("Invalid dictionary")
    result.add indent&"var "&scopevar&" = newScopeRef(nil)"
    result.add op&"MinValue(kind: minDictionary, scope: "&scopevar&")"
  of tkSymbol:
    result = @[op&"MinValue(kind: minSymbol, symVal: "&p.a.escapeEx&")"]
    p.a = ""
    discard getToken(p)
  else:
    raiseUndefined(p, "Undefined value: '"&p.a&"'")

proc print*(a: MinValue) =
  stdout.write($$a)
  stdout.flushFile()

# Predicates

proc isNull*(s: MinValue): bool =
  return s.kind == minNull

proc isSymbol*(s: MinValue): bool =
  return s.kind == minSymbol

proc isQuotation*(s: MinValue): bool =
  return s.kind == minQuotation

proc isCommand*(s: MinValue): bool =
  return s.kind == minCommand

proc isString*(s: MinValue): bool =
  return s.kind == minString

proc isFloat*(s: MinValue): bool =
  return s.kind == minFloat

proc isInt*(s: MinValue): bool =
  return s.kind == minInt

proc isNumber*(s: MinValue): bool =
  return s.kind == minInt or s.kind == minFloat

proc isBool*(s: MinValue): bool =
  return s.kind == minBool

proc isStringLike*(s: MinValue): bool =
  return s.isSymbol or s.isString or (s.isQuotation and s.qVal.len == 1 and
      s.qVal[0].isSymbol)

proc isDictionary*(q: MinValue): bool =
  return q.kind == minDictionary

proc isTypedDictionary*(q: MinValue): bool =
  if q.isDictionary:
    return q.objType != ""
  return false

proc isTypedDictionary*(q: MinValue, t: string): bool =
  if q.isTypedDictionary:
    return q.objType == t
  return false

proc `==`*(a: MinValue, b: MinValue): bool {.inline,
    extern: "min_exported_symbol_eqeq".} =
  if not (a.kind == b.kind or (a.isNumber and b.isNumber)):
    return false
  if a.kind == minSymbol and b.kind == minSymbol:
    return a.symVal == b.symVal
  elif a.kind == minInt and b.kind == minInt:
    return a.intVal == b.intVal
  elif a.kind == minInt and b.kind == minFloat:
    return a.intVal.float == b.floatVal.float
  elif a.kind == minFloat and b.kind == minFloat:
    return a.floatVal == b.floatVal
  elif a.kind == minFloat and b.kind == minInt:
    return a.floatVal == b.intVal.float
  elif a.kind == b.kind:
    if a.kind == minString:
      return a.strVal == b.strVal
    elif a.kind == minBool:
      return a.boolVal == b.boolVal
    elif a.kind == minNull:
      return true
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
    elif a.kind == minDictionary:
      let aVal = a.dVal
      let bVal = b.dVal
      if aVal.len != bVal.len:
        return false
      else:
        for t in aVal.pairs:
          if not bVal.hasKey(t.key):
            return false
          let v1 = t.val
          let v2 = bVal[t.key]
          if v1.kind != v2.kind:
            return false
          if v1.kind == minValOp:
            return v1.val == v2.val
        if a.objType == "" and b.objType == "":
          return true
        elif a.objType != "" and b.objType != "":
          return a.objType == b.objType
        else:
          return false
  else:
    return false
