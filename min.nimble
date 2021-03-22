import 
  minpkg/core/meta

# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @[pkgName]
installFiles  = @["min.yml", "min.nim", "prelude.min", "help.json"]
installDirs   = @["minpkg"]

# Dependencies

requires "nim >= 1.4.0"

before install:
  exec "nimble install -y nifty"
  exec "nifty remove -f"
  exec "nifty install"
