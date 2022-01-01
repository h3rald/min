### New Features

* Added **quoted-symbol?** predicate.
* Added **get-raw** operator to retrieve information on an element of a quotation without evaluating it.
### Fixes and Improvements

* Miscellaneous documentation fixes.
* Now clearing the stack after every HTTP request received by **http-server**.
* Fixed #174 (cons operator was not creating a new quotation).
* Fixed #176 (times can now execute a quotation 0 times).
* Documented previously-undocumented **type** operator.
