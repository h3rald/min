### BREAKING CHANGES

- Renamed `ROOT` symbol to `global`. Also the built-in `lang` module is now called `global`.

### New Features

- Upgraded OpenSSL to v3.2.0
- Added the `min run <mmm>` command to (download, install globally, and) execute the `main` symbol of the the specified managed module. For example this functionality can be used to upgrade `.min` files using the `min-upgrade` managed module.
- mmm: It is now possible to install, uninstall, and update modules by specifying them via `<name>@<version>`.
- mmm: The version is now optional when installing, uninstalling, and updating modules (the name of the HEAD branch will be used, e.g. "master" or "main", typically).

### Fixes and Improvements

- Added check to prevent installing local managed modules in the HOME directory or $HOME/mmm.
- Changed `tokenize` symbol so that it returns the full token, including delimiters (for strings and comments).
- Fixed regression in `min compile` command introduced in the previews version due to parses changes.


