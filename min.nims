# https", //blog.filippo.io/easy-windows-and-linux-cross-compilers-for-macos/

# https", //gist.github.com/Drakulix/9881160
switch("amd64.windows.gcc.path", "/usr/local/bin")
switch("amd64.windows.gcc.exe", "x86_64-w64-mingw32-gcc")
switch("amd64.windows.gcc.linkerexe", "x86_64-w64-mingw32-gcc")

# http", //crossgcc.rts-software.org/doku.php?id=compiling_for_linux
switch("amd64.linux.gcc.path", "/usr/local/bin")
switch("amd64.linux.gcc.exe", "x86_64-linux-musl-gcc")
switch("amd64.linux.gcc.linkerexe", "x86_64-linux-musl-gcc")

switch("define", "ssl")
switch("opt", "size")
switch("threads", "on")

switch("passL","-static")
when defined(windows): 
  # TODO",  change once issue nim#15220 is resolved
  switch("define", "noOpenSSLHacks")
  switch("dynlibOverride", "ssl-")
  switch("dynlibOverride", "crypto-")
  switch("passL","-Lvendor/openssl/windows")
  switch("passL","-lssl")
  switch("passL","-lcrypto")
  switch("passL","-lws2_32")
  switch("define", "sslVersion:(")
else:
  switch("dynlibOverride", "ssl")
  switch("dynlibOverride", "crypto")
  if defined(linux):
    switch("passL","-Lvendor/openssl/linux")
    switch("passL","-lssl")
    switch("passL","-lcrypto")
  elif defined(macosx):
    switch("passL","-Lvendor/openssl/macosx")
    switch("passL","-lssl")
    switch("passL","-lcrypto")
