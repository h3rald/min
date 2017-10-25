{.pragma: rtl, exportc, dynlib, cdecl.}
include "dynlibprocs/mindyn.nim"

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
