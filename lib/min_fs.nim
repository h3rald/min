import 
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

  def.finalize("fs")
