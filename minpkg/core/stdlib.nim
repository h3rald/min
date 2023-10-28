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
  ../lib/[min_lang,
  min_stack,
  min_seq,
  min_dict,
  min_num,
  min_str,
  min_logic,
  min_time,
  min_sys,
  min_io,
  min_dstore,
  min_fs,
  min_xml,
  min_http,
  min_net,
  min_crypto,
  min_math]

const PRELUDE* = "../../prelude.min".slurp.strip
var customPrelude* {.threadvar.}: string
customPrelude = ""

proc stdLib*(i: In) =
  setLogFilter(logging.lvlNotice)
  if not MINSYMBOLS.fileExists:
    MINSYMBOLS.writeFile("{}")
  if not MINHISTORY.fileExists:
    MINHISTORY.writeFile("")
  if not MINRC.fileExists:
    MINRC.writeFile("")
  i.lang_module
  i.stack_module
  i.seq_module
  i.dict_module
  i.logic_module
  i.num_module
  i.str_module
  i.time_module
  i.sys_module
  i.fs_module
  i.dstore_module
  i.io_module
  i.crypto_module
  i.net_module
  i.math_module
  i.http_module
  i.xml_module
  if customPrelude == "":
    i.eval PRELUDE, "<prelude>"
  else:
    try:
      i.eval customPrelude.readFile, customPrelude
    except CatchableError:
      logging.warn("Unable to process custom prelude code in $1" % customPrelude)
  try:
    i.eval MINRC.readFile()
  except CatchableError:
    error "An error occurred evaluating the .minrc file."
