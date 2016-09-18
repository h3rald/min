import
  os

const version* = "1.0.0-dev"

when defined(windows):
  const HOME* = getenv("USERPROFILE")
when not defined(windows):
  const HOME* = getenv("HOME")

const MINIMRC* = HOME / ".minimrc"
const MINIMSYMBOLS* = HOME / ".minim_symbols"
const MINIMHISTORY* = HOME / ".minim_history"

