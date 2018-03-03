import 
  strutils, 
  os,
  times
import 
  ../core/parser, 
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
    var info = newSeq[MinValue](0).newVal(i.scope)
    info.qVal.add @["name".newVal, s].newVal(i.scope)
    info.qVal.add @["device".newVal, fi.id.device.BiggestInt.newVal].newVal(i.scope)
    info.qVal.add @["file".newVal, fi.id.file.BiggestInt.newVal].newVal(i.scope)
    info.qVal.add @["type".newVal, fi.kind.filetype.newVal].newVal(i.scope)
    info.qVal.add @["size".newVal, fi.size.newVal].newVal(i.scope)
    info.qVal.add @["permissions".newVal, fi.permissions.unixPermissions.newVal].newVal(i.scope)
    info.qVal.add @["nlinks".newVal, fi.linkCount.newVal].newVal(i.scope)
    info.qVal.add @["ctime".newVal, fi.creationTime.toUnix.newVal].newVal(i.scope)
    info.qVal.add @["atime".newVal, fi.lastAccessTime.toUnix.newVal].newVal(i.scope)
    info.qVal.add @["mtime".newVal, fi.lastWriteTime.toUnix.newVal].newVal(i.scope)
    i.push info

  def.symbol("ftype") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getFileInfo.kind.filetype.newVal

  def.symbol("fperms") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getFilePermissions.unixPermissions.newVal

  def.finalize("fs")
