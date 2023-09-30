import
  std/[strutils,
  os,
  json]

proc reverse*[T](xs: openarray[T]): seq[T] =
  result = newSeq[T](xs.len)
  for i, x in xs:
    result[result.len-i-1] = x

proc simplifyPath*(filename: string, f: string): string =
  let file = strutils.replace(f, "\\", "/")
  let fn = strutils.replace(filename, "./", "")
  var dirs: seq[string] = fn.split("/")
  discard dirs.pop
  let pwd = dirs.join("/")
  if pwd == "":
    result = file
  else:
    result = pwd&"/"&file

proc unix*(s: string): string =
  return s.replace("\\", "/")

proc parentDirEx*(s: string): string =
  return s.parentDir

proc escapeEx*(s: string, unquoted = false): string =
  if unquoted:
    return s.escapeJsonUnquoted
  return s.escapeJson
