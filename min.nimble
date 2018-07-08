# Package

version       = "0.18.0"
author        = "Fabio Cevasco"
description   = "A tiny concatenative programming language and shell."
license       = "MIT"
bin           = @["min"]

# Dependencies

requires "nim >= 0.18.0"
requires "nifty"

before install:
  exec "nifty install"
