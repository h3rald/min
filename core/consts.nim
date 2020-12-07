import 
  strutils

const ymlconfig = "../min.yml".slurp

var pkgName* {.threadvar.}: string
var pkgVersion* {.threadvar.}: string
var pkgAuthor* {.threadvar.}: string
var pkgDescription* {.threadvar.}: string

for line in ymlconfig.split("\n"):
  let pair = line.split(":")
  if pair[0].strip == "name":
    pkgName = pair[1].strip
  if pair[0].strip == "version":
    pkgVersion = pair[1].strip
  if pair[0].strip == "author":
    pkgAuthor = pair[1].strip
  if pair[0].strip == "description":
    pkgDescription = pair[1].strip
