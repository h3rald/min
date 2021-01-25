import 
  os, 
  osproc, 
  strutils,
  critbits,
  logging
when not defined(lite):
  import sequtils
import 
  ../core/parser, 
  ../core/env,
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../core/fileutils

when not defined(lite):
  import ../packages/nim-miniz/src/nim_miniz

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
    i.push list.newVal
  
  def.symbol("ls-r") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    var list = newSeq[MinValue](0)
    for i in walkDirRec(a.getString):
      list.add newVal(i.unix)
    i.push list.newVal

  def.symbol("system") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    i.push execShellCmd(a.getString).newVal

  def.symbol("run") do (i: In):
    let vals = i.expect("'sym")
    let cmd = vals[0]
    let res = execCmdEx(cmd.getString)
    var d = newDict(i.scope)
    i.dset(d, "output", res.output.newVal)
    i.dset(d, "code", res.exitCode.newVal)
    i.push(d)
  
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
    let f = vals[0].getString
    var found = false
    if MINCOMPILED:
      let cf = strutils.replace(strutils.replace(f, "\\", "/"), "./", "")
      
      found = COMPILEDASSETS.hasKey(cf)
    if found:
      i.push true.newVal
    else:
      i.push newVal(f.fileExists or f.dirExists)
    
  def.symbol("file?") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0].getString
    var found = false
    if MINCOMPILED:
      let cf = strutils.replace(strutils.replace(f, "\\", "/"), "./", "")
      
      found = COMPILEDASSETS.hasKey(cf)
    if found:
      i.push true.newVal
    else:
      i.push f.fileExists.newVal
    
  def.symbol("dir?") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.dirExists.newVal
    
  def.symbol("rm") do (i: In):
    let vals = i.expect("'sym")
    let v = vals[0]
    let f = v.getString
    if f.fileExists:
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
    i.pushSym("get-env")

  def.symbol("!") do (i: In):
    i.pushSym("system")

  def.symbol("&") do (i: In):
    i.pushSym("run")

  def.sigil("$") do (i: In):
    i.pushSym("get-env")

  def.sigil("!") do (i: In):
    i.pushSym("system")

  def.sigil("&") do (i: In):
    i.pushSym("run")

  when not defined(lite):
    def.symbol("unzip") do (i: In):
      let vals = i.expect("'sym", "'sym")
      let dir = vals[0]
      let f = vals[1]
      nim_miniz.unzip(f.getString, dir.getString)

    def.symbol("zip") do (i: In):
      let vals = i.expect("'sym", "quot")
      let file = vals[0]
      let files = vals[1]
      nim_miniz.zip(files.qVal.mapIt(it.getString), file.getString)

  def.finalize("sys")
    
