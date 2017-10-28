{.pragma: rtl, exportc, dynlib, cdecl.}
type
  DynInfo* = object
    moduleName*: string # The name of the symbol to load and run
    dynlibVersion*: int # The version of the interface the dynlib is built for. This should increase if the interface changes

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
proc raiseInvalid(msg: string) {.importc, extern:"raiseInvalid_Emp5jFVyMCrh15i1fpFZiQ".}
proc raiseUndefined(msg: string) {.importc, extern:"raiseUndefined_Emp5jFVyMCrh15i1fpFZiQ_2".}
proc raiseOutOfBounds(msg: string) {.importc, extern:"raiseOutOfBounds_Emp5jFVyMCrh15i1fpFZiQ_3".}
proc raiseEmptyStack() {.importc, extern:"raiseEmptyStack_TxAgT9bR9codeB2uLmVKwt3w".}
proc newScope(parent: ref MinScope): MinScope {.importc, extern:"newScope_rH9cNZXpQjLoAhnola5cX4Q".}
proc newScopeRef(parent: ref MinScope): ref MinScope {.importc, extern:"newScopeRef_s7aB4NQYrY7Hev87iAW4jw".}
proc open(my: var MinParser, input: Stream, filename: string) {.importc, extern:"open_9brvHSJ7qjV9aGAqIpwcMV3A".}
proc close(my: var MinParser) {.importc, extern:"close_vmj9agDNIDvOwQZe8A2kGIAparser".}
proc getInt(my: MinParser): int {.importc, extern:"getInt_bXIqXGzvO9aGBMkrzA6B15gparser".}
proc getFloat(my: MinParser): float {.importc, extern:"getFloat_VXTaXBiGVD6XkIZK3YSq5Aparser".}
proc kind(my: MinParser): MinEventKind {.importc, extern:"kind_tgDyDbkEOSH9aIKWnOecz4Aparser".}
proc getColumn(my: MinParser): int {.importc, extern:"getColumn_bXIqXGzvO9aGBMkrzA6B15g_2parser".}
proc getLine(my: MinParser): int {.importc, extern:"getLine_bXIqXGzvO9aGBMkrzA6B15g_3parser".}
proc getFilename(my: MinParser): string {.importc, extern:"getFilename_s9a5R24VyFqQ3N3m7ZkDqmAparser".}
proc errorMsg(my: MinParser, msg: string): string {.importc, extern:"errorMsg_cVsoiM0SE9cH0KWBNfKqZcA".}
proc errorMsg(my: MinParser): string {.importc, extern:"errorMsg_r87VYrPzvmEsJhjriyvyQw".}
proc errorMsgExpected(my: MinParser, e: string): string {.importc, extern:"errorMsgExpected_Wqyr2ROfsYVJGDFwgiczQw".}
proc raiseParsing(p: MinParser, msg: string) {.importc, extern:"raiseParsing_Tz7DX0jKGOjDMX8SFWqb1A".}
proc raiseUndefined(p:MinParser, msg: string) {.importc, extern:"raiseUndefined_Tz7DX0jKGOjDMX8SFWqb1A_2".}
proc parseNumber(my: var MinParser) {.importc, extern:"parseNumber_q1Bg9ctZWMedsyrbTHRwU9aQ".}
proc handleHexChar(c: char, x: var int): bool {.importc, extern:"handleHexChar_5qj5zQ9aD5ka0UVtIDvSjNg".}
proc parseString(my: var MinParser): MinTokenKind {.importc, extern:"parseString_e3KFIguKCxnkZTqCF3o3jg".}
proc parseSymbol(my: var MinParser): MinTokenKind {.importc, extern:"parseSymbol_4hcHuz8N3YVsotvxzfL3Kw".}
proc skip(my: var MinParser) {.importc, extern:"skip_iFcpIZyA9cJx6updYRSgzjw".}
proc getToken(my: var MinParser): MinTokenKind {.importc, extern:"getToken_e3KFIguKCxnkZTqCF3o3jg_2".}
proc next(my: var MinParser) {.importc, extern:"next_iFcpIZyA9cJx6updYRSgzjw_2".}
proc eat(p: var MinParser, token: MinTokenKind) {.importc, extern:"eat_WE9bi5nLbQn9cAjnzHQ9bV6Kw".}
proc parseMinValue(p: var MinParser, i: In): MinValue {.importc, extern:"parseMinValue_Y6xeteQ253Mvf1JjLWhFig".}
proc `$`(a: MinValue): string {.importc, extern:"dollar__byT09beg0JPSCPWB3NVBb9bQ".}
proc `$$`(a: MinValue): string {.importc, extern:"dollardollar__byT09beg0JPSCPWB3NVBb9bQ_2".}
proc print(a: MinValue) {.importc, extern:"print_az8I9cfVT9b9bR2oSHjBwYE9bQ".}
proc `==`(a: MinValue, b: MinValue): bool {.importc, extern:"eqeq__zMKrLdJOCGuSouwNLkqPvQ".}
proc typeName*(v: MinValue): string {.importc, extern:"typeName_81jMzzfB0Qc0O4DsVU5arg".}
proc isSymbol*(s: MinValue): bool {.importc, extern:"isSymbol_BKcj9aQlJC73fcAZURf0pHw".}
proc isQuotation*(s: MinValue): bool {.importc, extern:"isQuotation_BKcj9aQlJC73fcAZURf0pHw_2".}
proc isString*(s: MinValue): bool {.importc, extern:"isString_BKcj9aQlJC73fcAZURf0pHw_3".}
proc isFloat*(s: MinValue): bool {.importc, extern:"isFloat_BKcj9aQlJC73fcAZURf0pHw_4".}
proc isInt*(s: MinValue): bool {.importc, extern:"isInt_BKcj9aQlJC73fcAZURf0pHw_5".}
proc isNumber*(s: MinValue): bool {.importc, extern:"isNumber_BKcj9aQlJC73fcAZURf0pHw_6".}
proc isBool*(s: MinValue): bool {.importc, extern:"isBool_BKcj9aQlJC73fcAZURf0pHw_7".}
proc isStringLike*(s: MinValue): bool {.importc, extern:"isStringLike_BKcj9aQlJC73fcAZURf0pHw_8".}
proc isDictionary*(q: MinValue): bool {.importc, extern:"isDictionary_7f9afQ8e7zZDtSeY6FzGNrw".}
proc newVal*(s: string): MinValue {.importc, extern:"newVal_JF8l73VBhy9cJEUaMht6wZA".}
proc newVal*(s: cstring): MinValue {.importc, extern:"newVal_MSseSJELDL5qivFR59byJ8Q".}
proc newVal*(q: seq[MinValue], parentScope: ref MinScope): MinValue {.importc, extern:"newVal_1PJ4YdZbCuyyD9bQkH2eu6A".}
proc newVal*(s: BiggestInt): MinValue {.importc, extern:"newVal_xDcIKp9bEb37NZkc9bhRat9cQ".}
proc newVal*(s: BiggestFloat): MinValue {.importc, extern:"newVal_ipbzO9cNeJyt42iGojkGmgg".}
proc newVal*(s: bool): MinValue {.importc, extern:"newVal_3PdI7sQ7HL5wBrAMsSG5sQ".}
proc newSym*(s: string): MinValue {.importc, extern:"newSym_JF8l73VBhy9cJEUaMht6wZA_2".}
proc getString*(v: MinValue): string {.importc, extern:"getString_81jMzzfB0Qc0O4DsVU5arg_2".}
proc define*(i: In): ref MinScope {.importc, extern:"define_HtvBzo0skz2GBYAKuFddKA".}
proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.importc, extern:"symbol_D4i19cVxxCgOFsbGlV20kyQ".}
proc symbol*(scope: ref MinScope, sym: string, v: MinValue) {.importc, extern:"symbol_XrX9bLAdrrQ3LgR9a9aYCQDXA".}
proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.importc, extern:"sigil_D4i19cVxxCgOFsbGlV20kyQ_2".}
proc sigil*(scope: ref MinScope, sym: string, v: MinValue) {.importc, extern:"sigil_XrX9bLAdrrQ3LgR9a9aYCQDXA_2".}
proc finalize*(scope: ref MinScope, name: string) {.importc, extern:"finalize_Igz9a7Xvo9cCa28si6nE0p5A".}
proc dget*(q: MinValue, s: MinValue): MinValue {.importc, extern:"dget_mfiqh3xcyXvnw9ajEytZuIA".}
proc dhas*(q: MinValue, s: MinValue): bool {.importc, extern:"dhas_MEAApOlp4yH17chuSa0k9bA".}
proc ddel*(i: In, p: MinValue, s: MinValue): MinValue {.importc, extern:"ddel_Riw3bw1BbxVPbq6m4TtOjw".}
proc dset*(i: In, p: MinValue, s: MinValue, m: MinValue): MinValue {.importc, extern:"dset_17HpKix9agOFpoPvvopNcCA".}
proc keys*(i: In, q: MinValue): MinValue {.importc, extern:"keys_oXC9bS9cwNWVkX1wVKP9aFEGA".}
proc values*(i: In, q: MinValue): MinValue {.importc, extern:"values_oXC9bS9cwNWVkX1wVKP9aFEGA_2".}
proc `%`*(a: MinValue): JsonNode {.importc, extern:"percent__QWqVWTWlpTitafp2NrtHgw".}
proc fromJson*(i: In, json: JsonNode): MinValue {.importc, extern:"fromJson_xPRwXdsUk4l7MGnYd2GbVA".}
proc reverse[T](xs: openarray[T]): seq[T] {.importc, extern:"reverse_drwb9cipBBt6vULs9c1MUijg".}
proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] {.importc, extern:"expect_EYb0Rd1E6Tl9bqxEJWylifg".}
proc reqQuotationOfQuotations*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"reqQuotationOfQuotations_Xy0o2sh9cpmSUTDb9cbQNwQg".}
proc reqQuotationOfNumbers*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"reqQuotationOfNumbers_Xy0o2sh9cpmSUTDb9cbQNwQg_2".}
proc reqQuotationOfSymbols*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"reqQuotationOfSymbols_Xy0o2sh9cpmSUTDb9cbQNwQg_3".}
proc reqTwoNumbersOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.importc, extern:"reqTwoNumbersOrStrings_iouGpQgslNcuoSL0Wzu7kQ".}
proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) {.importc, extern:"reqStringOrQuotation_Xy0o2sh9cpmSUTDb9cbQNwQg_4".}
proc reqTwoQuotationsOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.importc, extern:"reqTwoQuotationsOrStrings_iouGpQgslNcuoSL0Wzu7kQ_2".}
proc reqTwoSimilarTypesNonSymbol*(i: var MinInterpreter, a, b: var MinValue) {.importc, extern:"reqTwoSimilarTypesNonSymbol_iouGpQgslNcuoSL0Wzu7kQ_3".}
proc copy*(s: ref MinScope): ref MinScope {.importc, extern:"copy_KGlnVwWC9c0GiqXFwLDTiww".}
proc getSymbol*(scope: ref MinScope, key: string): MinOperator {.importc, extern:"getSymbol_fLEzdqSpt81S0Of5t4H9afg".}
proc hasSymbol*(scope: ref MinScope, key: string): bool {.importc, extern:"hasSymbol_58ut1Z9aCNCsBFnk7k9a9cVKA".}
proc delSymbol*(scope: ref MinScope, key: string): bool {.importc, extern:"delSymbol_58ut1Z9aCNCsBFnk7k9a9cVKA_2".}
proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator, override = false): bool {.importc, extern:"setSymbol_i9bO9b9aWD4K9c3RcQs0RqQvPw".}
proc getSigil*(scope: ref MinScope, key: string): MinOperator {.importc, extern:"getSigil_fLEzdqSpt81S0Of5t4H9afg_2".}
proc hasSigil*(scope: ref MinScope, key: string): bool {.importc, extern:"hasSigil_58ut1Z9aCNCsBFnk7k9a9cVKA_3".}
proc previous*(scope: ref MinScope): ref MinScope {.importc, extern:"previous_wp9cZN2pi3N79at4ESdxFNVQ".}
proc raiseRuntime*(msg: string, qVal: var seq[MinValue]) {.importc, extern:"raiseRuntime_t8oUDThVodY80ZU1ov5Z9cQ".}
proc dump*(i: MinInterpreter): string {.importc, extern:"dump_QNAGfSm5dAMbe9cao1yAs9bg".}
proc debug*(i: In, value: MinValue) {.importc, extern:"debug_e4IWAT3CueUziUEgqNhCEA".}
proc debug*(i: In, value: string) {.importc, extern:"debug_lPtsJwNzbYFsAR31JL52GA".}
proc newMinInterpreter*(filename: string): MinInterpreter {.importc, extern:"newMinInterpreter_XvlvXMt0JDVisNg0vLdKLQ".}
proc copy*(i: MinInterpreter, filename: string): MinInterpreter {.importc, extern:"copy_gOoDr5ILrrcZmPeoNmvPmg".}
proc formatError(sym: MinValue, message: string): string {.importc, extern:"formatError_c89a9aMhg9av88jUAkonIhspw".}
proc formatTrace(sym: MinValue): string {.importc, extern:"formatTrace_TfxbUETR0myClep3aQiOxA".}
proc stackTrace(i: In) {.importc, extern:"stackTrace_jfgtXM0Fziq5qAA4WP56DA".}
proc error(i: In, message: string) {.importc, extern:"error_KPzdvl74rfHwj1Zjzl9clSQ".}
proc open*(i: In, stream:Stream, filename: string) {.importc, extern:"open_0S1akx2yO9cGND7o1a5E4Pg".}
proc close*(i: In) {.importc, extern:"close_jfgtXM0Fziq5qAA4WP56DA_2".}
proc apply*(i: In, op: MinOperator) {.importc, extern:"apply_rdLuMUFDgimLSTje2hi9a9cw".}
proc push*(i: In, val: MinValue)  {.importc, extern:"push_5Bl42rKgV9afPr4fSWYKCQQ".}
proc dequote*(i: In, q: var MinValue) {.importc, extern:"dequote_iIi9a4U4PSOa3lI3GtpF9a2g".}
proc apply*(i: In, q: var MinValue) {.importc, extern:"apply_iIi9a4U4PSOa3lI3GtpF9a2g_2".}
proc pop*(i: In): MinValue {.importc, extern:"pop_kQ2ndJ8jYAFjieSQojhyOA".}
proc peek*(i: MinInterpreter): MinValue {.importc, extern:"peek_iWvRjZI9bPYXgbwT9bMlY33g".}
proc interpret*(i: In): MinValue {.importc, extern:"interpret_XWC8a7Zv9bICBdwhFZC4oFw".}
proc eval*(i: In, s: string, name: string) {.importc, extern:"eval_IB9cHX0kT7i7VJ1JVxalc0g".}
proc load*(i: In, s: string) {.importc, extern:"load_0LYMivTZTdTPkcMxl9cGHiw".}
proc filetype*(p: PathComponent): string {.importc, extern:"filetype_FZiFjJo8tLR4Z31M0hOccg".}
proc unixPermissions*(s: set[FilePermission]): int {.importc, extern:"unixPermissions_yRhMgkace1wP9a9cKdvJCJhw".}
proc toFilePermissions*(p: BiggestInt): set[FilePermission] {.importc, extern:"toFilePermissions_iFbq0Qn5CDseGqlJex9cAkw".}
