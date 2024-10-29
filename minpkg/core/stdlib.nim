import
  std/[
    logging,
    os,
    strutils
  ]

import
  env,
  parser,
  interpreter

import
  ../lib/[min_global,
  min_stack,
  min_dict,
  min_time,
  min_sys,
  min_io,
  min_store,
  min_fs,
  min_xml,
  min_http,
  min_net,
  min_crypto,
  min_gui,
  min_math]

var customPrelude* {.threadvar.}: string
customPrelude = ""

proc stdLib*(i: In) =
  if not MINSYMBOLS.fileExists:
    MINSYMBOLS.writeFile("{}")
  if not MINHISTORY.fileExists:
    MINHISTORY.writeFile("")
  if not MINRC.fileExists:
    MINRC.writeFile("")
  i.global_module
  i.stack_module
  i.dict_module
  i.time_module
  i.sys_module
  i.fs_module
  i.store_module
  i.io_module
  i.crypto_module
  i.net_module
  i.math_module
  i.http_module
  i.xml_module
  i.gui_module
  if customPrelude != "":
    try:
      i.eval customPrelude.readFile, customPrelude
    except CatchableError:
      logging.warn("Unable to process custom prelude code in $1" % customPrelude)
  try:
    i.eval MINRC.readFile()
  except CatchableError:
    error "An error occurred evaluating the .minrc file."
