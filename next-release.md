### New Functionality

* No longer auto-quoting values.
* Introduced the concept of _lambda keys_ (`^`-prefixed) for dictionaries, for storing executable quotations.
* Added `dict.lambda` symbol store operators in dictionaries.

### Fixes and Improvements

* `sys.ls-r` now returns directories and symlinks as well.
* Fixed compilation of dictionary literals (Closes #194).
* Displaying hint message in case of unhandled exceptions (Closes #196).
* Updated vendor library paths to include architecture information as well.
* Fixed resolution of static libraries based on min sources rather than current project.
* Upgraded OpenSSL to version 4.0.0.

