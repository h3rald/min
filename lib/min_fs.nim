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
    i.push s.getString.getLastModificationTime.toSeconds.newVal

  def.symbol("atime") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getLastAccessTime.toSeconds.newVal

  def.symbol("ctime") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getCreationTime.toSeconds.newVal

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
    info.qVal.add @["name".newSym, s].newVal(i.scope)
    info.qVal.add @["device".newSym, fi.id.device.newVal].newVal(i.scope)
    info.qVal.add @["file".newSym, fi.id.file.newVal].newVal(i.scope)
    info.qVal.add @["type".newSym, fi.kind.filetype.newVal].newVal(i.scope)
    info.qVal.add @["size".newSym, fi.size.newVal].newVal(i.scope)
    info.qVal.add @["permissions".newSym, fi.permissions.unixPermissions.newVal].newVal(i.scope)
    info.qVal.add @["nlinks".newSym, fi.linkCount.newVal].newVal(i.scope)
    info.qVal.add @["ctime".newSym, fi.creationTime.toSeconds.newVal].newVal(i.scope)
    info.qVal.add @["atime".newSym, fi.lastAccessTime.toSeconds.newVal].newVal(i.scope)
    info.qVal.add @["mtime".newSym, fi.lastWriteTime.toSeconds.newVal].newVal(i.scope)
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
