{.pragma: rtl, exportc, dynlib, cdecl.}
# Everything below here is to interface with the main program
# Import for the missing types (Look into importing just type definitions)
import 
  lexbase,
  streams,
  critbits,
  json,
  os

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

# parser.nim
proc raiseInvalid(msg: string) {.importc, extern:"min_exported_symbol_$1".}
proc raiseUndefined(msg: string) {.importc, extern:"min_exported_symbol_$1".}
proc raiseOutOfBounds(msg: string) {.importc, extern:"min_exported_symbol_$1".}
proc raiseEmptyStack() {.importc, extern:"min_exported_symbol_$1".}
proc newScope(parent: ref MinScope): MinScope {.importc, extern:"min_exported_symbol_$1".}
proc newScopeRef(parent: ref MinScope): ref MinScope {.importc, extern:"min_exported_symbol_$1".}
proc open(my: var MinParser, input: Stream, filename: string) {.importc, extern:"min_exported_symbol_$1".}
proc close(my: var MinParser) {.importc, extern:"min_exported_symbol_$1".}
proc getInt(my: MinParser): int {.importc, extern:"min_exported_symbol_$1".}
proc getFloat(my: MinParser): float {.importc, extern:"min_exported_symbol_$1".}
proc kind(my: MinParser): MinEventKind {.importc, extern:"min_exported_symbol_$1".}
proc getColumn(my: MinParser): int {.importc, extern:"min_exported_symbol_$1".}
proc getLine(my: MinParser): int {.importc, extern:"min_exported_symbol_$1".}
proc getFilename(my: MinParser): string {.importc, extern:"min_exported_symbol_$1".}
proc errorMsg(my: MinParser, msg: string): string {.importc, extern:"min_exported_symbol_$1".}
proc errorMsg(my: MinParser): string {.importc, extern:"min_exported_symbol_$1_2".}
proc errorMsgExpected(my: MinParser, e: string): string {.importc, extern:"min_exported_symbol_$1".}
proc raiseParsing(p: MinParser, msg: string) {.importc, extern:"min_exported_symbol_$1".}
proc raiseUndefined(p:MinParser, msg: string) {.importc, extern:"min_exported_symbol_$1_2".}
proc getToken(my: var MinParser): MinTokenKind {.importc, extern:"min_exported_symbol_$1".}
proc next(my: var MinParser) {.importc, extern:"min_exported_symbol_$1".}
proc eat(p: var MinParser, token: MinTokenKind) {.importc, extern:"min_exported_symbol_$1".}
proc parseMinValue(p: var MinParser, i: In): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc `$`(a: MinValue): string {.importc, extern:"min_exported_symbol_$1".}
proc `$$`(a: MinValue): string {.importc, extern:"min_exported_symbol_$1".}
proc print(a: MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc `==`(a: MinValue, b: MinValue): bool {.importc, extern:"min_exported_symbol_eqeq".}

# value.nim
proc typeName*(v: MinValue): string {.importc, extern:"min_exported_symbol_$1".}
proc isSymbol*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isQuotation*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isString*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isFloat*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isInt*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isNumber*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isBool*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isStringLike*(s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc isDictionary*(q: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc newVal*(s: string): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc newVal*(s: cstring): MinValue {.importc, extern:"min_exported_symbol_$1_2".}
proc newVal*(q: seq[MinValue], parentScope: ref MinScope): MinValue {.importc, extern:"min_exported_symbol_$1_3".}
proc newVal*(s: BiggestInt): MinValue {.importc, extern:"min_exported_symbol_$1_4".}
proc newVal*(s: BiggestFloat): MinValue {.importc, extern:"min_exported_symbol_$1_5".}
proc newVal*(s: bool): MinValue {.importc, extern:"min_exported_symbol_$1_6".}
proc newSym*(s: string): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc getFloat*(v: MinValue): float {.importc, extern:"min_exported_symbol_$1".}
proc getString*(v: MinValue): string {.importc, extern:"min_exported_symbol_$1".}

# utils.nim
proc define*(i: In): ref MinScope {.importc, extern:"min_exported_symbol_$1".}
proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.importc, extern:"min_exported_symbol_$1".}
proc symbol*(scope: ref MinScope, sym: string, v: MinValue) {.importc, extern:"min_exported_symbol_$1_2".}
proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.importc, extern:"min_exported_symbol_$1".}
proc sigil*(scope: ref MinScope, sym: string, v: MinValue) {.importc, extern:"min_exported_symbol_$1_2".}
proc finalize*(scope: ref MinScope, name: string) {.importc, extern:"min_exported_symbol_$1".}
proc dget*(q: MinValue, s: MinValue): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc dhas*(q: MinValue, s: MinValue): bool {.importc, extern:"min_exported_symbol_$1".}
proc ddel*(i: In, p: MinValue, s: MinValue): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc dset*(i: In, p: MinValue, s: MinValue, m: MinValue): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc keys*(i: In, q: MinValue): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc values*(i: In, q: MinValue): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc `%`*(a: MinValue): JsonNode {.importc, extern:"min_exported_symbol_percent".}
proc fromJson*(i: In, json: JsonNode): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc reverse[T](xs: openarray[T]): seq[T] {.importc, extern:"min_exported_symbol_$1".}
proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] {.importc, extern:"min_exported_symbol_$1".}
proc reqQuotationOfQuotations*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc reqQuotationOfNumbers*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc reqQuotationOfSymbols*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc reqTwoNumbersOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc reqTwoQuotationsOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc reqTwoSimilarTypesNonSymbol*(i: var MinInterpreter, a, b: var MinValue) {.importc, extern:"min_exported_symbol_$1".}

# scope.nim
proc copy*(s: ref MinScope): ref MinScope {.importc, extern:"min_exported_symbol_$1".}
proc getSymbol*(scope: ref MinScope, key: string): MinOperator {.importc, extern:"min_exported_symbol_$1".}
proc hasSymbol*(scope: ref MinScope, key: string): bool {.importc, extern:"min_exported_symbol_$1".}
proc delSymbol*(scope: ref MinScope, key: string): bool {.importc, extern:"min_exported_symbol_$1".}
proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator, override: bool): bool {.importc, extern:"min_exported_symbol_$1".}
proc getSigil*(scope: ref MinScope, key: string): MinOperator {.importc, extern:"min_exported_symbol_$1".}
proc hasSigil*(scope: ref MinScope, key: string): bool {.importc, extern:"min_exported_symbol_$1".}
proc previous*(scope: ref MinScope): ref MinScope {.importc, extern:"min_exported_symbol_$1".}

# interpreter.nim
proc raiseRuntime*(msg: string, qVal: var seq[MinValue]) {.importc, extern:"min_exported_symbol_$1".}
proc dump*(i: MinInterpreter): string {.importc, extern:"min_exported_symbol_$1".}
proc debug*(i: In, value: MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc debug*(i: In, value: string) {.importc, extern:"min_exported_symbol_$1_2".}
proc newMinInterpreter*(filename: string): MinInterpreter {.importc, extern:"min_exported_symbol_$1".}
proc copy*(i: MinInterpreter, filename: string): MinInterpreter {.importc, extern:"min_exported_symbol_$1_2".}
proc formatError(sym: MinValue, message: string): string {.importc, extern:"min_exported_symbol_$1".}
proc formatTrace(sym: MinValue): string {.importc, extern:"min_exported_symbol_$1".}
proc stackTrace(i: In) {.importc, extern:"min_exported_symbol_$1".}
proc error(i: In, message: string) {.importc, extern:"min_exported_symbol_$1".}
proc open*(i: In, stream:Stream, filename: string) {.importc, extern:"min_exported_symbol_$1_2".}
proc close*(i: In) {.importc, extern:"min_exported_symbol_$1_2".}
proc apply*(i: In, op: MinOperator) {.importc, extern:"min_exported_symbol_$1".}
proc push*(i: In, val: MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc dequote*(i: In, q: var MinValue) {.importc, extern:"min_exported_symbol_$1".}
proc apply*(i: In, q: var MinValue) {.importc, extern:"min_exported_symbol_$1_2".}
proc pop*(i: In): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc peek*(i: MinInterpreter): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc interpret*(i: In): MinValue {.importc, discardable, extern:"min_exported_symbol_$1".}
proc eval*(i: In, s: string, name: string, parseOnly: bool) {.importc, discardable, extern:"min_exported_symbol_$1".}
proc load*(i: In, s: string, parseOnly: bool): MinValue {.importc, discardable, extern:"min_exported_symbol_$1".}
proc parse*(i: In, s: string, name: string): MinValue {.importc, extern:"min_exported_symbol_$1".}
proc read*(i: In, s: string): MinValue {.importc, extern:"min_exported_symbol_$1".}

# fileutils.nim
proc filetype*(p: PathComponent): string {.importc, extern:"min_exported_symbol_$1".}
proc unixPermissions*(s: set[FilePermission]): int {.importc, extern:"min_exported_symbol_$1".}
proc toFilePermissions*(p: BiggestInt): set[FilePermission] {.importc, extern:"min_exported_symbol_$1".}
