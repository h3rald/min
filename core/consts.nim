import
  os,
  parsecfg,
  streams,
  strutils

const
  cfgfile   = "../minim.nimble".slurp

var
  appname*  = "MiNiM"
  version*: string
  f = newStringStream(cfgfile)

if f != nil:
  var p: CfgParser
  open(p, f, "../minim.nimble")
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
      stderr.writeLine("Configuration error.")
      quit(1)
    else: 
      discard
  close(p)
else:
  stderr.writeLine("Cannot process configuration file.")
  quit(2)



when defined(windows):
  const HOME* = getenv("USERPROFILE")
when not defined(windows):
  const HOME* = getenv("HOME")

const MINIMRC* = HOME / ".minimrc"
const MINIMSYMBOLS* = HOME / ".minim_symbols"
const MINIMHISTORY* = HOME / ".minim_history"

