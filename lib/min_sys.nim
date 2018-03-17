import 
  tables, 
  os, 
  osproc, 
  strutils,
  sequtils,
  logging
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
  let def = i.define()
  
  def.symbol(".") do (i: In):
    i.push newVal(getCurrentDir().unix)
    
  def.symbol("..") do (i: In):
    i.push newVal(getCurrentDir().parentDir.unix)
  
  def.symbol("cd") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0].getString
    i.pwd = joinPath(getCurrentDir(), f)
    info("Current directory changed to: ", i.pwd)
    f.setCurrentDir
  
  def.symbol("ls") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    var list = newSeq[MinValue](0)
    for i in walkDir(a.getString):
      list.add newVal(i.path.unix)
    i.push list.newVal(i.scope)
  
  def.symbol("ls-r") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    var list = newSeq[MinValue](0)
    for i in walkDirRec(a.getString):
      list.add newVal(i.unix)
    i.push list.newVal(i.scope)

  def.symbol("system") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    i.push execShellCmd(a.getString).newVal
  
  def.symbol("run") do (i: In):
    let vals = i.expect("'sym")
    let cmd = vals[0]
    let res = execCmdEx(cmd.getString)
    i.push @[@["output".newVal, res.output.newVal].newVal(i.scope), @["code".newVal, res.exitCode.newVal].newVal(i.scope)].newVal(i.scope)
  
  def.symbol("get-env") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    i.push a.getString.getEnv.newVal
  
  def.symbol("put-env") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let key = vals[0]
    let value = vals[1]
    key.getString.putEnv value.getString
    
  def.symbol("env?") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.existsEnv.newVal

  def.symbol("which") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.findExe.newVal

  def.symbol("os") do (i: In):
    i.push hostOS.newVal
  
  def.symbol("cpu") do (i: In):
    i.push hostCPU.newVal
  
  def.symbol("exists?") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push newVal(f.getString.fileExists or f.getString.dirExists)
    
  def.symbol("file?") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.fileExists.newVal
    
  def.symbol("dir?") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.dirExists.newVal
    
  def.symbol("rm") do (i: In):
    let vals = i.expect("'sym")
    let v = vals[0]
    let f = v.getString
    if f.existsFile:
      f.removeFile
    else:
      raiseInvalid("File '$1' does not exist." % f)
    
  def.symbol("cp") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let a = vals[0]
    let b = vals[1]
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
    
  def.symbol("mv") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let a = vals[0]
    let b = vals[1]
    let src = b.getString
    var dest = a.getString
    if dest.dirExists:
      dest = dest / src.extractFilename 
    moveFile src, dest
  
  def.symbol("rmdir") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    f.getString.removeDir
  
  def.symbol("mkdir") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    f.getString.createDir

  def.symbol("sleep") do (i: In):
    let vals = i.expect("int")
    let ms = vals[0]
    sleep ms.intVal.int

  def.symbol("chmod") do (i: In):
    let vals = i.expect("int", "string")
    let perms = vals[0]
    let s = vals[1]
    s.getString.setFilePermissions(perms.intVal.toFilePermissions)

  def.symbol("symlink?") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.symlinkExists.newVal

  def.symbol("symlink") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let dest = vals[0]
    let src = vals[1]
    src.getString.createSymlink dest.getString

  def.symbol("hardlink") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let dest = vals[0]
    let src = vals[1]
    src.getString.createHardlink dest.getString

  def.symbol("filename") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.extractFilename.unix.newVal

  def.symbol("dirname") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.parentDir.unix.newVal

  def.symbol("$") do (i: In):
    i.push("get-env".newSym)

  def.symbol("!") do (i: In):
    i.push("system".newSym)

  def.symbol("&") do (i: In):
    i.push("run".newSym)

  def.sigil("$") do (i: In):
    i.push("get-env".newSym)

  def.sigil("!") do (i: In):
    i.push("system".newSym)

  def.sigil("&") do (i: In):
    i.push("run".newSym)

  when not defined(lite):
    def.symbol("unzip") do (i: In):
      let vals = i.expect("'sym", "'sym")
      let dir = vals[0]
      let f = vals[1]
      miniz.unzip(f.getString, dir.getString)

    def.symbol("zip") do (i: In):
      let vals = i.expect("'sym", "quot")
      let file = vals[0]
      let files = vals[1]
      miniz.zip(files.qVal.mapIt(it.getString), file.getString)

  def.finalize("sys")
    
