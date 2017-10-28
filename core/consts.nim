import
  os,
  parsecfg,
  streams,
  strutils,
  logging

const
  cfgfile   = "../min.nimble".slurp

var
  appname*  = "min"
  version*: string
  f = newStringStream(cfgfile)

if f != nil:
  var p: CfgParser
  open(p, f, "../min.nimble")
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgKeyValuePair:
      case e.key:
        of "version":
          version = e.value
        else:
          discard
    of cfgError:
      fatal("Configuration error.")
      quit(1)
    else: 
      discard
  close(p)
else:
  fatal("Cannot process configuration file.")
  quit(2)


var HOME*: string
if defined(windows):
  HOME = getenv("USERPROFILE")
if not defined(windows):
  HOME = getenv("HOME")

let MINRC* = HOME / ".minrc"
let MINSYMBOLS* = HOME / ".min_symbols"
let MINHISTORY* = HOME / ".min_history"
let MINLIBS* = HOME / ".minlibs"
