proc reverse*[T](xs: openarray[T]): seq[T] =
  result = newSeq[T](xs.len)
  for i, x in xs:
    result[result.len-i-1] = x 


when defined(mini):
  import
    strutils
  
  proc parentDirEx*(s: string): string =
    let fslash = s.rfind("/")
    let bslash = s.rfind("\\")
    var dirEnd = fslash-1
    if dirEnd < 0:
      dirEnd = bslash-1
    if dirEnd < 0:
      dirEnd = s.len-1
    if dirEnd < 0:
      return s
    return s[0..dirEnd]
    
else:
  import os
  proc parentDirEx*(s: string): string =
    return s.parentDir
