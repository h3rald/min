import tables, os, osproc, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

  # OS
  
define("sys")

  .symbol("pwd") do (i: In):
    i.push newVal(getCurrentDir())
  
  .symbol("cd") do (i: In):
    var f: MinValue
    i.reqString f
    f.strVal.setCurrentDir
  
  .symbol("ls") do (i: In):
    var a: MinValue
    i.reqString a
    var list = newSeq[MinValue](0)
    for i in walkdir(a.strVal):
      list.add newVal(i.path)
    i.push list.newVal
  
  .symbol("system") do (i: In):
    var a: MinValue
    i.reqString a
    i.push execShellCmd(a.strVal).newVal
  
  .symbol("run") do (i: In):
    var a: MinValue
    i.reqString a
    let words = a.strVal.split(" ")
    let cmd = words[0]
    var args = newSeq[string](0)
    if words.len > 1:
      args = words[1..words.len-1]
    i.push execProcess(cmd, args, nil, {poUsePath}).newVal
  
  .symbol("getenv") do (i: In):
    var a: MinValue
    i.reqString a
    i.push a.strVal.getEnv.newVal
  
  .symbol("putenv") do (i: In):
    var key, value: MinValue
    i.reqTwoStrings key, value
    key.strVal.putEnv value.strVal
  
  .symbol("os") do (i: In):
    i.push hostOS.newVal
  
  .symbol("cpu") do (i: In):
    i.push hostCPU.newVal
  
  .symbol("file?") do (i: In):
    var f: MinValue
    i.reqString f
    i.push f.strVal.fileExists.newVal
  
  .symbol("dir?") do (i: In):
    var f: MinValue
    i.reqString f
    i.push f.strVal.dirExists.newVal
  
  .symbol("rm") do (i: In):
    var f: MinValue
    i.reqString f
    f.strVal.removeFile
  
  .symbol("cp") do (i: In):
    var a, b: MinValue
    i.reqTwoStrings a, b
    copyFile b.strVal, a.strVal
  
  .symbol("mv") do (i: In):
    var a, b: MinValue
    i.reqTwoStrings a, b
    moveFile b.strVal, a.strVal
  
  .symbol("rmdir") do (i: In):
    var f: MinValue
    i.reqString f
    f.strVal.removeDir
  
  .symbol("mkdir") do (i: In):
    var f: MinValue
    i.reqString f
    f.strVal.createDir

   .symbol("sleep") do (i: In):
     var ms: MinValue
     i.reqInt ms
     sleep ms.intVal

  .finalize()
