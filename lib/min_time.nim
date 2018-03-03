import 
  times, 
  tables
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

# Time


proc time_module*(i: In)=
  let def = i.define()
  
  def.symbol("timestamp") do (i: In):
    i.push getTime().int.newVal
  
  def.symbol("now") do (i: In):
    i.push epochTime().newVal
  
  def.symbol("timeinfo") do (i: In):
    let vals = i.expect("num")
    let t = vals[0]
    var time: Time
    if t.kind == minInt:
      time = t.intVal.fromUnix
    else:
      time = t.floatVal.int64.fromUnix
    let tinfo = time.local
    var info = newSeq[MinValue](0).newVal(i.scope)
    info.qVal.add @["year".newVal, tinfo.year.newVal].newVal(i.scope)
    info.qVal.add @["month".newVal, (tinfo.month.int+1).newVal].newVal(i.scope)
    info.qVal.add @["day".newVal, tinfo.monthday.newVal].newVal(i.scope)
    info.qVal.add @["weekday".newVal, (tinfo.weekday.int+1).newVal].newVal(i.scope)
    info.qVal.add @["yearday".newVal, tinfo.yearday.newVal].newVal(i.scope)
    info.qVal.add @["hour".newVal, tinfo.hour.newVal].newVal(i.scope)
    info.qVal.add @["minute".newVal, tinfo.minute.newVal].newVal(i.scope)
    info.qVal.add @["second".newVal, tinfo.second.newVal].newVal(i.scope)
    info.qVal.add @["dst".newVal, tinfo.isDST.newVal].newVal(i.scope)
    info.qVal.add @["timezone".newVal, tinfo.utcOffset.newVal].newVal(i.scope)
    i.push info

  def.symbol("to-timestamp") do (i: In):
    let vals = i.expect("dict")
    let dict = vals[0]
    try:
      let year = dict.dget("year".newVal).intVal.int
      let month = dict.dget("month".newVal).intVal.int - 1
      let monthday = dict.dget("day".newVal).intVal.int
      let hour = dict.dget("hour".newVal).intVal.int
      let minute = dict.dget("minute".newVal).intVal.int
      let second = dict.dget("second".newVal).intVal.int
      let dst = dict.dget("dst".newVal).boolVal
      let timezone = dict.dget("timezone".newVal).intVal.int
      let tinfo = Datetime(year: year, month: Month(month), monthday: monthday, hour: hour, minute: minute, second: second, isDST: dst, utcOffset: timezone)
      i.push tinfo.toTime.toUnix.int.newVal
    except:
      raiseInvalid("An invalid timeinfo dictionary was provided.")

  def.symbol("datetime") do (i: In):
    let vals = i.expect("num")
    let t = vals[0]
    var time: Time
    if t.kind == minInt:
      time = t.intVal.fromUnix
    else:
      time = t.floatVal.int64.fromUnix
    i.push time.utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'").newVal

  def.symbol("tformat") do (i: In):
    let vals = i.expect("string", "num")
    let s = vals[0]
    let t = vals[1]
    var time: Time
    if t.kind == minInt:
      time = t.intVal.fromUnix
    else:
      time = t.floatVal.int64.fromUnix
    i.push time.local.format(s.getString).newVal
  
  def.finalize("time")
