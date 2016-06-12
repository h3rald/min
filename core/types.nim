import lexbase, critbits

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
      of minInt: intVal*: int
      of minFloat: floatVal*: float
      of minQuotation: 
        qVal*: seq[MinValue]
        scope*: ref MinScope
        objType*: string
        obj*: pointer
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
  MinOperator* = proc (i: In)
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

