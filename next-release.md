* Added **apply-interpolate** (alias: **=%**) operator.
* Documented that it is possible also to interpolate with named placeholders, like this: `"Current Directory: $pwd" ("pwd" .) =%`
* Added **from-yaml** and **to-yaml** operators. Note that they only support dictionaries containing string values (primarily intended to access extremely simple YAML files containing just key/value pairs).
* Added **from-semver**, **to-semver**, **semver-major**, **semver-minor**, **semver-patch**, **semver** operators to manage version strings conforming to [Semantic Versioning](https://semver.org/) (additional labels are not yet supported).
* Automatically adding **.min** to files supplied to the min executable if they don't already end in .min.
* Fixed GC safety issues
* Now statically linking libssl and libcrypto on all platform to provide HTTPS support out of the box
* Now using a set of min tasks to perform a min release and other common operations
* Added **escape** operator to escape quotes and special characters in a string.
* Added **quit** operator to exit with a 0 code.
