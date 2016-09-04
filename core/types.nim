import lexbase, critbits, os

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
  MinScope* = object
    symbols*: CritBitTree[MinOperator]
    sigils*: CritBitTree[MinOperator]
    parent*: ref MinScope
    name*: string
    stack*: MinStack
  MinValue* = object
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
  MinStack* = seq[MinValue]
  MinInterpreter* = object
    stack*: MinStack
    pwd*: string
    scope*: ref MinScope
    parser*: MinParser
    currSym*: MinValue
    filename*: string
    debugging*: bool 
    evaluating*: bool 
    unsafe*: bool
  In* = var MinInterpreter
  Val* = var MinValue
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
  MinSigil* = proc (i: In, sym: string)
  MinParsingError* = ref object of ValueError 
  MinUndefinedError* = ref object of ValueError
  MinInvalidError* = ref object of ValueError
  MinEmptyStackError* = ref object of ValueError
  MinOutOfBoundsError* = ref object of ValueError
  MinRuntimeError* = ref object of SystemError
    qVal*: seq[MinValue]

proc isNotNil*[T](obj: T): bool =
  return not obj.isNil

const version* = "1.0.0-dev"

when defined(windows):
  const HOME* = getenv("HOMEPATH")
when not defined(windows):
  const HOME* = getenv("HOME")

const MINIMRC* = HOME / ".minimrc"
const MINIMSYMBOLS* = HOME / ".minim_symbols"
const MINIMHISTORY* = HOME / ".minim_history"

