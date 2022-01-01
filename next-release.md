### New Features

* Added **quoted-symbol?** predicate.
* Added **get-raw** operator to retrieve information on an element of a quotation without evaluating it.
* Added **dget-raw** operator to retrieve information on an element of a dictionary without evaluating it.
* Added **set-sym** operator to set an element of a quotation to a symbol (specified as a string).
* Added **dset-sym** operator to set a key of a dictionary to a symbol (specified as a string).
### Fixes and Improvements

* Miscellaneous documentation fixes.
* Now clearing the stack after every HTTP request received by **http-server**.
* Fixed #174 (cons operator was not creating a new quotation).
* Fixed #176 (times can now execute a quotation 0 times).
* **set** now actually creates a copy of the specified quotation.
* Documented previously-undocumented **type** operator.
