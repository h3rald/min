import
  times
import
  ../core/parser,
  ../core/value,
  ../core/interpreter,
  ../core/utils

proc time_module*(i: In)=
  let def = i.define()

  def.symbol("timestamp") do (i: In):
    i.push getTime().toUnix().newVal

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
    var info = newDict(i.scope)
    info.objType = "timeinfo"
    i.dset info, "year", tinfo.year.newVal
    i.dset info, "month", (tinfo.month.int+1).newVal
    i.dset info, "day", tinfo.monthday.newVal
    i.dset info, "weekday", (tinfo.weekday.int+1).newVal
    i.dset info, "yearday", tinfo.yearday.newVal
    i.dset info, "hour", tinfo.hour.newVal
    i.dset info, "minute", tinfo.minute.newVal
    i.dset info, "second", tinfo.second.newVal
    i.dset info, "dst", tinfo.isDST.newVal
    i.dset info, "timezone", tinfo.utcOffset.newVal
    i.push info

  def.symbol("to-timestamp") do (i: In):
    let vals = i.expect("dict:timeinfo")
    let dict = vals[0]
    try:
      let year = i.dget(dict, "year").intVal.int
      let month = Month(i.dget(dict, "month").intVal.int - 1)
      let monthday = MonthdayRange(i.dget(dict, "day").intVal.int)
      let hour: HourRange = i.dget(dict, "hour").intVal.int
      let minute: MinuteRange = i.dget(dict, "minute").intVal.int
      let second: SecondRange = i.dget(dict, "second").intVal.int
      let timezone = i.dget(dict, "timezone").intVal.int
      let tinfo = dateTime(year, month, monthday, hour, minute, second, 0, utc())
      i.push (tinfo + timezone.seconds).toTime.toUnix.int.newVal
    except CatchableError:
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
    let vals = i.expect("str", "num")
    let s = vals[0]
    let t = vals[1]
    var time: Time
    if t.kind == minInt:
      time = t.intVal.fromUnix
    else:
      time = t.floatVal.int64.fromUnix
    i.push time.local.format(s.getString).newVal

  def.finalize("time")