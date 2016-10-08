import
  os

import
  ../vendor/miniz


proc zip*(files: seq[string], filepath: string) =
  var pZip: ptr mz_zip_archive = cast[ptr mz_zip_archive](alloc0(sizeof(mz_zip_archive)))
  discard pZip.mz_zip_writer_init_file(filepath.cstring, 0)
  var comment: pointer
  for f in files:
    discard pZip.mz_zip_writer_add_file(f.extractFileName.cstring, f.extractFileName.cstring, comment, 0, cast[mz_uint](MZ_DEFAULT_COMPRESSION))
  discard pZip.mz_zip_writer_finalize_archive()
  discard pZip.mz_zip_writer_end()
  dealloc(pZip)

proc unzip*(src, dst: string) =
  var pZip: ptr mz_zip_archive = cast[ptr mz_zip_archive](alloc0(sizeof(mz_zip_archive)))
  discard pZip.mz_zip_reader_init_file(src.cstring, 0)
  let total = pZip.mz_zip_reader_get_num_files()
  if total == 0:
    return
  for i in 0.countup(total-1):
    let isDir = pZip.mz_zip_reader_is_file_a_directory(i)
    if isDir == 0:
      # Extract file
      let size = pZip.mz_zip_reader_get_filename(i, nil, 0)
      var filename: cstring = cast[cstring](alloc(size))
      discard pZip.mz_zip_reader_get_filename(i, filename, size)
      let dest = dst / $filename
      dest.parentDir.createDir()
      dest.writeFile("")
      discard pZip.mz_zip_reader_extract_to_file(i, dest, 0)
  discard pZip.mz_zip_reader_end()
  dealloc(pZip)
