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
  MinScope = object
    locals: CritBitTree[MinValue]
    symbols: CritBitTree[MinValue]
    sigils: CritBitTree[MinValue]
    parent: ref MinScope
    stack: MinStack
  MinValue* = object
    line*: int
    column*: int
    case kind*: MinKind
      of minInt: intVal*: int
      of minFloat: floatVal*: float
      of minQuotation: 
        qVal*: seq[MinValue]
        scope: MinScope
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
  EMinParsingError* = ref object of ValueError 
  EMinUndefinedError* = ref object of ValueError
  MinInterpreter* = object
    stack*: MinStack
    parser*: MinParser
    currSym*: MinValue
    filename*: string
    debugging*: bool 
    evaluating*: bool 
  MinOperator* = proc (i: var MinInterpreter)
  MinSigil* = proc (i: var MinInterpreter, sym: string)
  MinError* = enum
    errSystem,
    errParser,
    errGeneric,
    errEmptyStack,
    errNoQuotation,
    errUndefined,
    errIncorrect,
    errTwoNumbersRequired,
    errDivisionByZero
