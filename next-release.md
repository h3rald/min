### Breaking Changes

* No longer distributing lite and mini variants.
* Removed **regex** and **=~** symbols, use **search**, **replace**, **search-all**, **replace-apply** instead.
* Regular expressions are PCRE compliant.
* Renamed **match** into **match?**.
* The **split** operator now takes a PCRE as a separator.

### New features

* Now including statically-compiled PCRE V8.44 library used for regular expression support.
* Upgraded OpenSSL to v1.1.1j.
