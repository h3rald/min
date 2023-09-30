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

requires "nim >= 2.0.0 & < 3.0.0"
requires "checksums"
requires "zippy >= 0.5.6 & < 0.6.0" 
requires "nimquery >= 2.0.1 & < 3.0.0" 
requires "minline >= 0.1.1 & < 0.2.0"
