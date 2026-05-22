# Package

version       = "0.47.1"
author        = "Fabio Cevasco"
description   = "A small but practical concatenative programming language and shell."
license       = "MIT"
bin           = @["min"]
installExt    = @["nim", "c", "h", "a"]
installFiles  = @["min.yml", "min.nim", "help.json"]
skipFiles     = @["mintool.min"]
installDirs   = @["minpkg"]

# Dependencies

requires "nim >= 2.2.0 & < 3.0.0"
requires "checksums >= 0.2.1"
requires "zippy >= 0.5.6 & < 0.6.0" 
requires "nimquery >= 2.0.1 & < 3.0.0" 
requires "minline >= 0.1.2 & < 0.2.0"
requires "htmlparser >= 0.1.0 & < 0.2.0"
