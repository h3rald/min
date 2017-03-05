import 
  nake

import
  core/consts

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

proc filename_for(os: string, arch: string): string =
  return "min" & "_v" & version & "_" & os & "_" & arch & ".zip"

task "windows-x64-build", "Build min for Windows (x64)":
  direshell compile, windows_x64, hs_file

task "linux-x86-build", "Build min for Linux (x86)":
  direshell compile, linux_x86,  hs_file
  
task "linux-x64-build", "Build min for Linux (x64)":
  direshell compile, linux_x64,  hs_file
  
task "linux-arm-build", "Build min for Linux (ARM)":
  direshell compile, linux_arm,  hs_file
  
task "macosx-x64-build", "Build min for Mac OS X (x64)":
  direshell compile, macosx_x64, hs_file

task "release", "Release min":
  echo "\n\n\n WINDOWS - x64:\n\n"
  runTask "windows-x64-build"
  direshell zip, filename_for("windows", "x64"), hs & ".exe"
  direshell "rm", hs & ".exe"
  echo "\n\n\n LINUX - x64:\n\n"
  runTask "linux-x64-build"
  direshell zip, filename_for("linux", "x64"), hs 
  direshell "rm", hs 
  echo "\n\n\n LINUX - x86:\n\n"
  runTask "linux-x86-build"
  direshell zip, filename_for("linux", "x86"), hs 
  direshell "rm", hs 
  echo "\n\n\n LINUX - ARM:\n\n"
  runTask "linux-arm-build"
  direshell zip, filename_for("linux", "arm"), hs 
  direshell "rm", hs 
  echo "\n\n\n MAC OS X - x64:\n\n"
  runTask "macosx-x64-build"
  direshell zip, filename_for("macosx", "x64"), hs 
  direshell "rm", hs 
  echo "\n\n\n ALL DONE!"
