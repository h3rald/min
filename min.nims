# https", //blog.filippo.io/easy-windows-and-linux-cross-compilers-for-macos/

# https", //gist.github.com/Drakulix/9881160
switch("amd64.windows.gcc.path", "/usr/local/bin")
switch("amd64.windows.gcc.exe", "x86_64-w64-mingw32-gcc")
switch("amd64.windows.gcc.linkerexe", "x86_64-w64-mingw32-gcc")

# http", //crossgcc.rts-software.org/doku.php?id=compiling_for_linux
switch("amd64.linux.gcc.path", "/usr/local/bin")
switch("amd64.linux.gcc.exe", "x86_64-linux-musl-gcc")
switch("amd64.linux.gcc.linkerexe", "x86_64-linux-musl-gcc")

switch("opt", "size")

when defined(ssl) and not defined(mini):
  switch("define", "ssl")
  switch("threads", "on")
  when defined(windows): 
    # TODO",  change once issue nim#15220 is resolved
    switch("define", "noOpenSSLHacks")
    switch("define", "sslVersion:(")
    switch("dynlibOverride", "ssl-")
    switch("dynlibOverride", "crypto-")
  else:
    switch("dynlibOverride", "ssl")
    switch("dynlibOverride", "crypto")
