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
  i.define("time")
  
    .symbol("timestamp") do (i: In):
      i.push getTime().int.newVal
    
    .symbol("now") do (i: In):
      i.push epochTime().newVal
  
    .symbol("timeinfo") do (i: In):
      var t: MinValue
      i.reqNumber t
      var time: Time
      if t.kind == minInt:
        time = t.intVal.fromSeconds
      else:
        time = t.floatVal.fromSeconds
      let tinfo = time.timeToTimeInfo
      var info = newSeq[MinValue](0).newVal
      info.qVal.add @["year".newSym, tinfo.year.newVal].newVal
      info.qVal.add @["month".newSym, (tinfo.month.int+1).newVal].newVal
      info.qVal.add @["day".newSym, tinfo.monthday.newVal].newVal
      info.qVal.add @["weekday".newSym, (tinfo.weekday.int+1).newVal].newVal
      info.qVal.add @["yearday".newSym, tinfo.yearday.newVal].newVal
      info.qVal.add @["hour".newSym, tinfo.hour.newVal].newVal
      info.qVal.add @["minute".newSym, tinfo.minute.newVal].newVal
      info.qVal.add @["second".newSym, tinfo.second.newVal].newVal
      i.push info

    .symbol("datetime") do (i: In):
      var t: MinValue
      i.reqNumber t
      var time: Time
      if t.kind == minInt:
        time = t.intVal.fromSeconds
      else:
        time = t.floatVal.fromSeconds
      i.push time.timeToTimeInfo.format("yyyy-MM-dd'T'HH:mm:ss'Z'").newVal

    .symbol("tformat") do (i: In):
      var t, s: MinValue
      i.reqString s
      i.reqNumber t
      var time: Time
      if t.kind == minInt:
        time = t.intVal.fromSeconds
      else:
        time = t.floatVal.fromSeconds
      i.push time.timeToTimeInfo.format(s.getString).newVal
    
    .finalize()
  
