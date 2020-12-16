import 
  core/meta

# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @[pkgName]
installFiles  = @["core/meta.nim"]

# Dependencies

requires "nim >= 1.4.0"

before install:
  exec "nimble install -y nifty"
  exec "nifty remove -f"
  exec "nifty install"
