import 
  os,
  times,
  strutils,
  critbits
import 
  ../core/env,
  ../core/parser, 
  ../core/baseutils, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../core/fileutils

proc fs_module*(i: In) =

  let def = i.define()

  def.symbol("mtime") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getLastModificationTime.toUnix.newVal

  def.symbol("atime") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getLastAccessTime.toUnix.newVal

  def.symbol("ctime") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getCreationTime.toUnix.newVal

  def.symbol("hidden?") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.isHidden.newVal

  def.symbol("fsize") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getFileSize.newVal

  def.symbol("fstats") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let fi = s.getString.getFileInfo
    var info = newDict(i.scope)
    i.dset(info, "name", s)
    i.dset(info, "device", fi.id.device.BiggestInt.newVal)
    i.dset(info, "file", fi.id.file.BiggestInt.newVal)
    i.dset(info, "type", fi.kind.filetype.newVal)
    i.dset(info, "size", fi.size.newVal)
    i.dset(info, "permissions", fi.permissions.unixPermissions.newVal)
    i.dset(info, "nlinks", fi.linkCount.newVal)
    i.dset(info, "ctime", fi.creationTime.toUnix.newVal)
    i.dset(info, "atime", fi.lastAccessTime.toUnix.newVal)
    i.dset(info, "mtime", fi.lastWriteTime.toUnix.newVal)
    i.push info

  def.symbol("ftype") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getFileInfo.kind.filetype.newVal

  def.symbol("fperms") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getFilePermissions.unixPermissions.newVal

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

  def.symbol("symlink?") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.symlinkExists.newVal

  def.symbol("filename") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.extractFilename.unix.newVal

  def.symbol("dirname") do (i: In):
    let vals = i.expect("'sym")
    let f = vals[0]
    i.push f.getString.parentDir.unix.newVal

  def.symbol("join-path") do (i: In):
    let vals = i.expect("quot")
    var fragments = newSeq[string](0)
    for p in vals[0].qVal:
      if not p.isStringLike:
        raiseInvalid("A quotation of strings is required")
      fragments.add(p.getString)
    i.push fragments.joinPath.newVal
  
  def.symbol("expand-filename") do (i: In):
    let vals = i.expect("'sym")
    i.push vals[0].getString.expandFilename.newVal

  def.symbol("expand-symlink") do (i: In):
    let vals = i.expect("'sym")
    i.push vals[0].getString.expandSymlink.newVal

  def.symbol("normalized-path") do (i: In):
    let vals = i.expect("'sym")
    var s = vals[0].getString
    s.normalizePath()
    i.push s.newVal

  def.symbol("relative-path") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let p = vals[1].getString
    let base = vals[0].getString
    i.push relativePath(p, base).newVal

  def.symbol("absolute-path") do (i: In):
    let vals = i.expect("'sym")
    i.push vals[0].getString.absolutePath.newVal

  def.symbol("windows-path") do (i: In):
    let vals = i.expect("'sym")
    i.push vals[0].getString.replace("/", "\\").newVal
  
  def.symbol("unix-path") do (i: In):
    let vals = i.expect("'sym")
    i.push vals[0].getString.replace("\\", "/").newVal

  def.symbol("absolute-path?") do (i: In):
    let vals = i.expect("'sym")
    i.push vals[0].getString.isAbsolute.newVal

  def.finalize("fs")
