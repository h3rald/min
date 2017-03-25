import 
  tables, 
  os, 
  osproc, 
  strutils,
  sequtils
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../core/fileutils

when not defined(lite):
  import ../packages/nim-miniz/miniz

proc unix(s: string): string =
  return s.replace("\\", "/")

proc sys_module*(i: In)=
  var sys = i.define()
  
  sys = sys.symbol(".") do (i: In):
    i.push newVal(getCurrentDir().unix)
    
  .symbol("..") do (i: In):
    i.push newVal(getCurrentDir().parentDir.unix)
  
  .symbol("cd") do (i: In):
    var f: MinValue
    i.reqStringLike f
    f.getString.setCurrentDir
  
  .symbol("ls") do (i: In):
    var a: MinValue
    i.reqStringLike a
    var list = newSeq[MinValue](0)
    for i in walkDir(a.getString):
      list.add newVal(i.path.unix)
    i.push list.newVal(i.scope)
  
  .symbol("ls-r") do (i: In):
    var a: MinValue
    i.reqStringLike a
    var list = newSeq[MinValue](0)
    for i in walkDirRec(a.getString):
      list.add newVal(i.unix)
    i.push list.newVal(i.scope)

  .symbol("system") do (i: In):
    var a: MinValue
    i.reqStringLike a
    i.push execShellCmd(a.getString).newVal
  
  .symbol("run") do (i: In):
    var cmd: MinValue
    i.reqStringLike cmd
    let res = execCmdEx(cmd.getString)
    i.push @[@["output".newSym, res.output.newVal].newVal(i.scope), @["code".newSym, res.exitCode.newVal].newVal(i.scope)].newVal(i.scope)
  
  .symbol("getenv") do (i: In):
    var a: MinValue
    i.reqStringLike a
    i.push a.getString.getEnv.newVal
  
  .symbol("putenv") do (i: In):
    var key, value: MinValue
    i.reqTwoStringLike key, value
    key.getString.putEnv value.getString
    
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
    i.reqStringLike f
    i.push f.getString.fileExists.newVal
    
  .symbol("dir?") do (i: In):
    var f: MinValue
    i.reqStringLike f
    i.push f.getString.dirExists.newVal
    
  .symbol("rm") do (i: In):
    var v: MinValue
    i.reqStringLike v
    let f = v.getString
    if f.existsFile:
      f.removeFile
    elif f.existsDir:
      f.removeDir
    else:
      raiseInvalid("File '$1' does not exist." % f)
    
  .symbol("cp") do (i: In):
    var a, b: MinValue
    i.reqTwoStringLike a, b
    let src = b.getString
    var dest = a.getString
    if src.dirExists:
      copyDirWithPermissions src, dest
    elif dest.dirExists:
      if src.dirExists:
        copyDirWithPermissions src, dest
      else:
        copyFileWithPermissions src, dest / src.extractFilename 
    else:
      copyFileWithPermissions src, dest 
    
  .symbol("mv") do (i: In):
    var a, b: MinValue
    i.reqTwoStringLike a, b
    let src = b.getString
    var dest = a.getString
    if dest.dirExists:
      dest = dest / src.extractFilename 
    moveFile src, dest
  
  .symbol("rmdir") do (i: In):
    var f: MinValue
    i.reqStringLike f
    f.getString.removeDir
  
  .symbol("mkdir") do (i: In):
    var f: MinValue
    i.reqStringLike f
    f.getString.createDir

   .symbol("sleep") do (i: In):
     var ms: MinValue
     i.reqInt ms
     sleep ms.intVal.int

  .symbol("chmod") do (i: In):
    var s, perms: MinValue
    i.reqIntAndString perms, s
    s.getString.setFilePermissions(perms.intVal.toFilePermissions)

  .symbol("symlink?") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.symlinkExists.newVal

  .symbol("symlink") do (i: In):
    var src, dest: MinValue
    i.reqTwoStringLike dest, src
    src.getString.createSymlink dest.getString

  .symbol("hardlink") do (i: In):
    var src, dest: MinValue
    i.reqTwoStringLike dest, src
    src.getString.createHardlink dest.getString

  .symbol("filename") do (i: In):
    var f: MinValue
    i.reqStringLike f
    i.push f.getString.extractFilename.unix.newVal

  .symbol("dirname") do (i: In):
    var f: MinValue
    i.reqStringLike f
    i.push f.getString.parentDir.unix.newVal

  .symbol("$") do (i: In):
    i.push("getenv".newSym)

  .symbol("!") do (i: In):
    i.push("system".newSym)

  .symbol("&") do (i: In):
    i.push("run".newSym)

  .sigil("$") do (i: In):
    i.push("getenv".newSym)

  .sigil("!") do (i: In):
    i.push("system".newSym)

  .sigil("&") do (i: In):
    i.push("run".newSym)

  when not defined(lite):
    sys = sys.symbol("unzip") do (i: In):
      var f, dir: MinValue
      i.reqTwoStringLike dir, f
      miniz.unzip(f.getString, dir.getString)

    .symbol("zip") do (i: In):
      var files, file: MinValue
      i.reqStringLikeAndQuotation file, files
      miniz.zip(files.qVal.mapIt(it.getString), file.getString)

  sys.finalize("sys")
    
