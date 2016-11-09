import
  os

# Filetype and permissions

proc filetype*(p: PathComponent): string =
  case p
  of pcFile:
    return "file"
  of pcLinkToFile:
    return "filelink"
  of pcDir:
    return "dir"
  of pcLinkToDir:
    return "dirlink"

proc unixPermissions*(s: set[FilePermission]): int =
  result = 0
  for p in s:
    case p:
    of fpUserRead:
      result += 400
    of fpUserWrite:
      result += 200
    of fpUserExec:
      result += 100
    of fpGroupRead:
      result += 40
    of fpGroupWrite:
      result += 20
    of fpGroupExec:
      result += 10
    of fpOthersRead:
      result += 4
    of fpOthersWrite:
      result += 2
    of fpOthersExec:
      result += 1

proc toFilePermissions*(p: BiggestInt): set[FilePermission] =
  let user = ($p)[0].int
  let group = ($p)[1].int
  let others = ($p)[2].int
  if user == 1:
    result.incl fpUserExec
  if user == 2:
    result.incl fpUserWrite
  if user == 3:
    result.incl fpUserExec
    result.incl fpUserWrite
  if user == 4:
    result.incl fpUserRead
  if user == 5:
    result.incl fpUserRead
    result.incl fpUserExec
  if user == 6:
    result.incl fpUserRead
    result.incl fpUserWrite
  if user == 7:
    result.incl fpUserRead
    result.incl fpUserWrite
    result.incl fpUserExec
  if group == 1:
    result.incl fpGroupExec
  if group == 2:
    result.incl fpGroupWrite
  if group == 3:
    result.incl fpGroupExec
    result.incl fpGroupWrite
  if group == 4:
    result.incl fpGroupRead
  if group == 5:
    result.incl fpGroupRead
    result.incl fpGroupExec
  if group == 6:
    result.incl fpGroupRead
    result.incl fpGroupWrite
  if group == 7:
    result.incl fpGroupRead
    result.incl fpGroupWrite
    result.incl fpGroupExec
  if others == 1:
    result.incl fpOthersExec
  if others == 2:
    result.incl fpOthersWrite
  if others == 3:
    result.incl fpOthersExec
    result.incl fpOthersWrite
  if others == 4:
    result.incl fpOthersRead
  if others == 5:
    result.incl fpOthersRead
    result.incl fpOthersExec
  if others == 6:
    result.incl fpOthersRead
    result.incl fpOthersWrite
  if others == 7:
    result.incl fpOthersRead
    result.incl fpOthersWrite
    result.incl fpOthersExec