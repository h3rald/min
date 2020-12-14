import
  logging,
  strutils,
  json

type  
  JsonLogger* = ref object of Logger

var JSONLOG* {.threadvar.}: JsonNode
JSONLOG = newJArray()

method log*(logger: JsonLogger; level: Level; args: varargs[string, `$`]) =
  if level >= getLogFilter() and level >= logger.levelThreshold:
    let msg = substituteLog(logger.fmtStr, level, args)
    var entry = newJObject()
    entry["message"] = %msg
    entry["level"] = %(LevelNames[level].toLowerAscii)
    JSONLOG.add entry

proc newJsonLogger*(levelThreshold = lvlAll; fmtStr = " "): JsonLogger =
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold
