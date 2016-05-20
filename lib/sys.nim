import tables, os, osproc, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# OS 

minsym "pwd", i:
  i.push newVal(getCurrentDir())

minsym "cd", i:
  let f = i.pop
  if f.isString:
    try:
      f.strVal.setCurrentDir
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error errIncorrect, "A string is required on the stack"

minsym "ls", i:
  let a = i.pop
  var list = newSeq[MinValue](0)
  if a.isString:
    if a.strVal.existsDir:
      for i in walkdir(a.strVal):
        list.add newVal(i.path)
      i.push list.newVal
    else:
      warn "Directory '$1' not found" % [a.strVal]
  else:
    i.error(errIncorrect, "A string is required on the stack")

minsym "system", i:
  let a = i.pop
  if a.isString:
    i.push execShellCmd(a.strVal).newVal
  else:
    i.error(errIncorrect, "A string is required on the stack")

minsym "run", i:
  let a = i.pop
  if a.isString:
    let words = a.strVal.split(" ")
    let cmd = words[0]
    var args = newSeq[string](0)
    if words.len > 1:
      args = words[1..words.len-1]
    i.push execProcess(cmd, args, nil, {poUsePath}).newVal
  else:
    i.error(errIncorrect, "A string is required on the stack")

minsym "getenv", i:
  let a = i.pop
  if a.isString:
    i.push a.strVal.getEnv.newVal
  else:
    i.error(errIncorrect, "A string is required on the stack")

minsym "putenv", i:
  let value = i.pop
  let key = i.pop
  if value.isString and key.isString:
    key.strVal.putEnv value.strVal
  else:
    i.error(errIncorrect, "Two strings are required on the stack")

minsym "os", i:
  i.push hostOS.newVal

minsym "cpu", i:
  i.push hostCPU.newVal

minsym "file?", i:
  let f = i.pop
  if f.isString:
    i.push f.strVal.fileExists.newVal
  else:
    i.error errIncorrect, "A string is required on the stack"

minsym "dir?", i:
  let f = i.pop
  if f.isString:
    i.push f.strVal.dirExists.newVal
  else:
    i.error errIncorrect, "A string is required on the stack"

minsym "rm", i:
  let f = i.pop
  if f.isString:
    try:
      f.strVal.removeFile
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error errIncorrect, "A string is required on the stack"

minsym "cp", i:
  let b = i.pop
  let a = i.pop
  if a.isString and b.isString:
    try:
      copyFile a.strVal, b.strVal
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error errIncorrect, "Two strings are required on the stack"

minsym "mv", i:
  let b = i.pop
  let a = i.pop
  if a.isString and b.isString:
    try:
      moveFile a.strVal, b.strVal
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error errIncorrect, "Two strings are required on the stack"

minsym "rmdir", i:
  let f = i.pop
  if f.isString:
    try:
      f.strVal.removeDir
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error errIncorrect, "A string is required on the stack"

minsym "mkdir", i:
  let f = i.pop
  if f.isString:
    try:
      f.strVal.createDir
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error errIncorrect, "A string is required on the stack"
