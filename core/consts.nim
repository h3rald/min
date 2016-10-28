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


var HOME*: string
if defined(windows):
  HOME = getenv("USERPROFILE")
if not defined(windows):
  HOME = getenv("HOME")

let MINIMRC* = HOME / ".minimrc"
let MINIMSYMBOLS* = HOME / ".minim_symbols"
let MINIMHISTORY* = HOME / ".minim_history"

