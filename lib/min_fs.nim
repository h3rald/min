import 
  strutils, 
  os,
  times
import 
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

proc fs_module*(i: In) =
  i.define("fs")
    .symbol("mtime") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getLastModificationTime.toSeconds.newVal

    .symbol("atime") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getLastAccessTime.toSeconds.newVal

    .symbol("ctime") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getCreationTime.toSeconds.newVal

    .symbol("hidden?") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.isHidden.newVal

    .symbol("fsize") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getFileSize.newVal

    .symbol("fstats") do (i: In):
      var s: MinValue
      i.reqStringLike s
      let fi = s.getString.getFileInfo
      var info = newSeq[MinValue](0).newVal
      info.qVal.add @["name".newSym, s].newVal
      info.qVal.add @["device".newSym, fi.id.device.newVal].newVal
      info.qVal.add @["file".newSym, fi.id.file.newVal].newVal
      info.qVal.add @["type".newSym, fi.kind.filetype.newVal].newVal
      info.qVal.add @["size".newSym, fi.size.newVal].newVal
      info.qVal.add @["permissions".newSym, fi.permissions.unixPermissions.newVal].newVal
      info.qVal.add @["nlinks".newSym, fi.linkCount.newVal].newVal
      info.qVal.add @["ctime".newSym, fi.creationTime.toSeconds.newVal].newVal
      info.qVal.add @["atime".newSym, fi.lastAccessTime.toSeconds.newVal].newVal
      info.qVal.add @["mtime".newSym, fi.lastWriteTime.toSeconds.newVal].newVal
      i.push info

    .symbol("ftype") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getFileInfo.kind.filetype.newVal

    .symbol("fperms") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getFilePermissions.unixPermissions.newVal

    .finalize()
