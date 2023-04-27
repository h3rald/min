import 
  minpkg/core/meta

# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @[pkgName]
installExt    = @["nim", "c", "h", "a"]
installFiles  = @["min.yml", "min.nim", "prelude.min", "help.json"]
installDirs   = @["minpkg"]

# Dependencies

requires "nim >= 1.6.12, zippy >= 0.5.6"

before install:
  exec "nimble install -y nifty"
  exec "nifty remove -f"
  exec "nifty install"
