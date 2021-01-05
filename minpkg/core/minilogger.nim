import
  strutils

type
  Level* = enum lvlAll, lvlDebug, lvlInfo, lvlNotice, lvlWarn, lvlError, lvlFatal, lvlNone
  
const
  LevelNames: array[Level, string] = [ "DEBUG", "DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL", "NONE"]

var LOGLEVEL* {.threadvar.}: Level
LOGLEVEL = lvlNotice

proc logPrefix(level: Level): string =
  case level:
    of lvlDebug:
      return ("---")
    of lvlInfo:
      return ("(i)")
    of lvlNotice:
      return ("   ")
    of lvlWarn:
      return ("(!)")
    of lvlError:
      return ("(!)")
    of lvlFatal:
      return ("(x)")
    else:
      return ("   ")

proc log*(level: Level; args: varargs[string, `$`]) =
  var f = stdout
  if level >= LOGLEVEL:
    if level >= lvlWarn: 
      f = stderr
    let prefix = level.logPrefix()
    f.write(prefix&" ")
    f.write(args.join(" "))
    f.write("\n")
    if level in {lvlError, lvlFatal}: flushFile(f)

proc fatal*(args: varargs[string, `$`]) =
    log(lvlFatal, args)

proc error*(args: varargs[string, `$`]) =
    log(lvlError, args)

proc warn*(args: varargs[string, `$`]) =
    log(lvlWarn, args)

proc notice*(args: varargs[string, `$`]) =
    log(lvlNotice, args)

proc info*(args: varargs[string, `$`]) =
    log(lvlInfo, args)

proc debug*(args: varargs[string, `$`]) =
    log(lvlDebug, args)

proc getLogLevel*(): string =
  return LevelNames[LOGLEVEL].toLowerAscii

proc setLogFilter*(lvl: Level) =
    LOGLEVEL = lvl

proc setLogLevel*(val: var string): string {.discardable.} =
  var lvl: Level
  case val:
    of "debug":
      lvl = lvlDebug
    of "info":
      lvl = lvlInfo
    of "notice":
      lvl = lvlNotice
    of "warn":
      lvl = lvlWarn
    of "error":
      lvl = lvlError
    of "fatal":
      lvl = lvlFatal
    of "none":
      lvl = lvlNone
    else:
      val = "warn"
      lvl = lvlWarn
  LOGLEVEL = lvl
  return val