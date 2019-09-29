import 
  core/consts

# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @["min"]
installFiles  = @["core/consts.nim"]

# Dependencies

requires "nim >= 1.0.0"
requires "nifty"

before install:
  exec "nifty install"

# Tasks

const
  compile = "nim c -d:release"
  linux_x86 = "--cpu:i386 --os:linux"
  linux_x64 = "--cpu:amd64 --os:linux"
  linux_arm = "--cpu:arm --os:linux"
  windows_x64 = "--cpu:amd64 --os:windows"
  macosx_x64 = ""
  parallel = "--parallelBuild:1 --verbosity:3"
  hs = "min"
  hs_file = "min.nim"
  zip = "zip -X"

proc shell(command, args: string, dest = "") =
  exec command & " " & args & " " & dest

proc filename_for(os: string, arch: string): string =
  return "min" & "_v" & version & "_" & os & "_" & arch & ".zip"

task windows_x64_build, "Build min for Windows (x64)":
  shell compile, windows_x64, hs_file

task linux_x64_build, "Build min for Linux (x64)":
  shell compile, linux_x64,  hs_file
  
task macosx_x64_build, "Build min for Mac OS X (x64)":
  shell compile, macosx_x64, hs_file

task release, "Release min":
  echo "\n\n\n WINDOWS - x64:\n\n"
  windows_x64_buildTask()
  shell zip, filename_for("windows", "x64"), hs & ".exe"
  shell "rm", hs & ".exe"
  echo "\n\n\n LINUX - x64:\n\n"
  linux_x64_buildTask()
  shell zip, filename_for("linux", "x64"), hs 
  shell "rm", hs 
  echo "\n\n\n MAC OS X - x64:\n\n"
  macosx_x64_buildTask()
  shell zip, filename_for("macosx", "x64"), hs 
  shell "rm", hs 
  echo "\n\n\n ALL DONE!"
