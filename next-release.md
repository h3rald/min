### Breaking Changes

* No longer distributing lite and mini variants.
* Removed **regex** and **=~** symbols, use **search**, **replace**, **search-all**, **replace-apply** instead.
* Regular expressions are PCRE compliant.
* Renamed **match** into **match?**.

### New features

* Now includng statically-compiled PCRE V8.44 library used for regular expression support.
