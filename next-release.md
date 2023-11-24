### BREAKING CHANGES

* SSL is now enabled by default when installing via nimble and when compiling by default. Use `-d:nossl` to disable.

### New Features

* min shell now supports syntax highlighting for entered values.
* Implemented smart completion for invocations in min shell.
* Implemented new `tokenize` symbol.
* Added syntax highlighting to code examples on min site.

### Fixes and Improvements

* Auto-completions for files and folders now automatically end with `"`.
* The min shell no longer attempts to auto-complete executables (it never worked properly anyway).

