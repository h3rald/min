## This is all you need to create a min module in Nim
## Compile with `nim c --app:lib --noMain -d:release dynamicadd.nim`
{.pragma: rtl, exportc, dynlib, cdecl.}
import mindyn

proc setup*(): DynInfo {.rtl.} =
  result = DynInfo(moduleName: "the_lib", dynlibVersion: 1) 

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
  def.finalize("dyn")
