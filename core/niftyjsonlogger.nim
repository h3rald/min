import
  logging,
  json
import
  ../packages/niftylogger

type  
  NiftyJsonLogger* = ref object of NiftyLogger

var JSONLOG* {.threadvar.}: JsonNode
JSONLOG = newJArray()

proc logPrefix*(level: Level): string =
  case level:
    of lvlDebug:
      return "---"
    of lvlInfo:
      return "(i)"
    of lvlNotice:
      return "   "
    of lvlWarn:
      return "(!)"
    of lvlError:
      return "(!)"
    of lvlFatal:
      return "(x)"
    else:
      return "   "

method log*(logger: NiftyJsonLogger; level: Level; args: varargs[string, `$`]) =
  echo args
  if level >= getLogFilter() and level >= logger.levelThreshold:
    let msg = substituteLog(logger.fmtStr, level, args)
    let prefix = level.logPrefix()
    var entry = newJObject()
    entry["message"] = %msg
    entry["prefix"] = %prefix
    entry["level"] = %($level)
    JSONLOG.add entry

proc newNiftyJsonLogger*(levelThreshold = lvlAll; fmtStr = " "): NiftyLogger =
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold
