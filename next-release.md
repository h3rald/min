### BREAKING CHANGES

* The `dpairs` symbol now returns a quotation of quotations, each containing a value/key pair.

### New Features

* Added `dev` symbol to toggle development mode within a min program.
* Implemented [mmm](http://localhost:1337/learn-mmm), i.e. _min module management_. The following new commands are now built-in into the min executable:
  * min init &mdash; Initialize a manage module.
  * min install &mdash; Install a managed module.
  * min uninstall &mdash; Uninstall a managed module.
  * min update &mdash; Update a managed module.
  * min list &mdash; List all dependent managed modules.
  * min search &mdash; Search for managed module.

### Fixes and Improvements

* Fixed `help` symbol and `min help` command to correctly report sigil documentation.
* Documented `~` (alias and sigil for `lambda-bind`) symbol.

