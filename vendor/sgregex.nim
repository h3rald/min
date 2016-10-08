{.compile: "libregex.c".}
const 
  RXSUCCESS* = 0
  RXEINMOD* = - 1
  RXEPART* = - 2
  RXEUNEXP* = - 3
  RXERANGE* = - 4
  RXELIMIT* = - 5
  RXEEMPTY* = - 6
  RXENOREF* = - 7
  RX_ALLMODS* = "mis"


type 
  srx_MemFunc* = proc (a2: pointer; a3: pointer; a4: csize): pointer

proc RX_STRLENGTHFUNC*(str: string): int = 
  return str.len

type 
  srx_Context* = pointer

{.push importc.}
proc srx_CreateExt*(str: cstring; strsize: csize; mods: cstring; errnpos: ptr cint; memfn: srx_MemFunc; memctx: pointer): ptr srx_Context
template srx_Create*(str, mods: string): ptr srx_Context = 
  srx_CreateExt(str, RX_STRLENGTHFUNC(str), mods, nil, nil, nil)

proc srx_Destroy*(R: ptr srx_Context): cint
proc srx_DumpToStdout*(R: ptr srx_Context)
proc srx_MatchExt*(R: ptr srx_Context; str: cstring; size: csize; 
                   offset: csize): cint
template srx_Match*(R: ptr srx_Context, str: cstring, off: csize): cint = 
  srx_MatchExt(R, str, RX_STRLENGTHFUNC(str), off)

proc srx_GetCaptureCount*(R: ptr srx_Context): cint
proc srx_GetCaptured*(R: ptr srx_Context; which: cint; pbeg: ptr csize; 
                      pend: ptr csize): cint
proc srx_GetCapturedPtrs*(R: ptr srx_Context; which: cint; 
                          pbeg: cstringArray; pend: cstringArray): cint
proc srx_ReplaceExt*(R: ptr srx_Context; str: cstring; strsize: csize; 
                     rep: cstring; repsize: csize; outsize: ptr csize): cstring
template srx_Replace*(R: ptr srx_Context, str: cstring, rep: cstring): cstring = 
  srx_ReplaceExt(R, str, RX_STRLENGTHFUNC(str), rep, RX_STRLENGTHFUNC(rep), nil)

proc srx_FreeReplaced*(R: ptr srx_Context; repstr: cstring)




