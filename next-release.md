### New Features

* By default, nimble builds are no longer statically linking other libraries.

### Fixes and Improvements

* Ensured that all the relevant procs are gcsafe.
* No longer using ref for `MinValue` objects.
* No longer performing a deep copy when dequoting.
* Optimized the way debug information is stored to reduce memory usage.
* Avoiding creating unnecessary scopes when possible (withScope macro already creates a scope).
* Fixed `setSigil` incorrectly calling `setSymbol`.
* Improved handling of hash bang.


