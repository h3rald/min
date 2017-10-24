{.pragma: rtl, exportc, dynlib, cdecl.}

#import 
#  core/parser,
#  core/value,
#  core/interpreter,
#  core/utils
import 
  lexbase,
  streams,
  critbits

type
  MinTokenKind* = enum
    tkError,
    tkEof,
    tkString,
    tkInt,
    tkFloat,
    tkBracketLe,
    tkBracketRi,
    tkSymbol,
    tkTrue,
    tkFalse
  MinKind* = enum
    minInt,
    minFloat,
    minQuotation,
    minString,
    minSymbol,
    minBool
  MinEventKind* = enum    ## enumeration of all events that may occur when parsing
    eMinError,             ## an error ocurred during parsing
    eMinEof,               ## end of file reached
    eMinString,            ## a string literal
    eMinInt,               ## an integer literal
    eMinFloat,             ## a float literal
    eMinQuotationStart,    ## start of an array: the ``(`` token
    eMinQuotationEnd       ## start of an array: the ``)`` token
  MinParserError* = enum        ## enumeration that lists all errors that can occur
    errNone,               ## no error
    errInvalidToken,       ## invalid token
    errStringExpected,     ## string expected
    errBracketRiExpected,  ## ``)`` expected
    errQuoteExpected,      ## ``"`` or ``'`` expected
    errEOC_Expected,       ## ``*/`` expected
    errEofExpected,        ## EOF expected
    errExprExpected
  MinParserState* = enum 
    stateEof,
    stateStart,
    stateQuotation,
    stateExpectValue
  MinParser* = object of BaseLexer
    a*: string
    token*: MinTokenKind
    state*: seq[MinParserState]
    kind*: MinEventKind
    err*: MinParserError
    filename*: string
  MinValue* = ref MinValueObject
  MinValueObject* = object
    line*: int
    column*: int
    filename*: string
    case kind*: MinKind
      of minInt: intVal*: BiggestInt
      of minFloat: floatVal*: BiggestFloat
      of minQuotation:
        qVal*: seq[MinValue]
        scope*: ref MinScope
      of minString: strVal*: string
      of minSymbol: symVal*: string
      of minBool: boolVal*: bool
  MinScope* = object
    symbols*: CritBitTree[MinOperator]
    sigils*: CritBitTree[MinOperator]
    parent*: ref MinScope
    name*: string
    stack*: MinStack
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

proc isSymbol*(s: MinValue): bool =
  return s.kind == minSymbol

proc isQuotation*(s: MinValue): bool = 
  return s.kind == minQuotation

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
  return s.isSymbol or s.isString or (s.isQuotation and s.qVal.len == 1 and s.qVal[0].isSymbol)

proc isDictionary*(q: MinValue): bool =
  if not q.isQuotation:
    return false
  if q.qVal.len == 0:
    return true
  for val in q.qVal:
    if not val.isQuotation or val.qVal.len != 2 or not val.qVal[0].isString:
      return false
  return true

proc newVal*(s: string): MinValue =
  return MinValue(kind: minString, strVal: s)

proc newVal*(s: cstring): MinValue =
  return MinValue(kind: minString, strVal: $s)

#proc newVal*(q: seq[MinValue], parentScope: ref MinScope): MinValue =
#  return MinValue(kind: minQuotation, qVal: q, scope: newScopeRef(parentScope))

proc newVal*(s: BiggestInt): MinValue =
  return MinValue(kind: minInt, intVal: s)

proc newVal*(s: BiggestFloat): MinValue =
  return MinValue(kind: minFloat, floatVal: s)

proc newVal*(s: bool): MinValue =
  return MinValue(kind: minBool, boolVal: s)

proc newSym*(s: string): MinValue =
  return MinValue(kind: minSymbol, symVal: s)

proc define(i: In): ref MinScope {.importc, extern: "define_HtvBzo0skz2GBYAKuFddKA".}
proc finalize(scope: ref MinScope, name: string) {.importc, extern: "finalize_Igz9a7Xvo9cCa28si6nE0p5A".}
proc symbol(scope: ref MinScope, sym: string, p: MinOperatorProc) {.importc, extern: "symbol_D4i19cVxxCgOFsbGlV20kyQ".}
proc expect(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] {.importc, extern: "expect_EYb0Rd1E6Tl9bqxEJWylifg".}
proc push(i: In, val: MinValue) {.importc, extern: "push_5Bl42rKgV9afPr4fSWYKCQQ".}

proc setup*(
    defineProc: proc(i: In): ref MinScope,
    finalizeProc: proc(scope: ref MinScope, name: string),
    symbolProc: proc(scope: ref MinScope, sym: string, p: MinOperatorProc),
    expectProc: proc(i: var MinInterpreter, elements: varargs[string]): seq[MinValue],
    pushProc: proc(i: In, val: MinValue)
  ): string {.rtl.} =
  result = "the_lib"

proc the_lib*(i: In) {.rtl.} =
  let def = i.define()
  def.symbol("myp") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(a.intVal + b.intVal)
      else:
        i.push newVal(a.intVal.float + b.floatVal)
    else:
      if b.isFloat:
        i.push newVal(a.floatVal + b.floatVal)
      else:
        i.push newVal(a.floatVal + b.intVal.float)
  def.finalize("dyn2")
