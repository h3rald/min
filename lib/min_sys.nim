import tables, os, osproc, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

  # OS
  

proc sys_module*(i: In)=
  i.define("sys")
  
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
      for i in walkDir(a.strVal):
        list.add newVal(i.path)
      i.push list.newVal
    
    .symbol("ls-r") do (i: In):
      var a: MinValue
      i.reqString a
      var list = newSeq[MinValue](0)
      for i in walkDirRec(a.strVal):
        list.add newVal(i)
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
    
    .symbol("env?") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.existsEnv.newVal

    .symbol("which") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.findExe.newVal

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
       sleep ms.intVal.int
  
    .symbol("chmod") do (i: In):
      var s, perms: MinValue
      i.reqStringAndNumber s, perms
      s.getString.setFilePermissions(perms.intVal.toFilePermissions)

    .symbol("symlink?") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.symlinkExists.newVal

    .symbol("symlink") do (i: In):
      var src, dest: MinValue
      i.reqTwoStrings dest, src
      src.getString.createSymlink dest.getString

    .symbol("hardlink") do (i: In):
      var src, dest: MinValue
      i.reqTwoStrings dest, src
      src.getString.createHardlink dest.getString

    .finalize()
