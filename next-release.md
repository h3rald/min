### BREAKING CHANGES

* Actually removed the `invoke` symbol that was supposed to be removed in v0.44.0 but didn't.
* Removed Dockerfile and Notepad++ highlighter (no longer maintained).

### Fixes and Improvements

* Implemented `define-sigil` (was documented but not actually implemented).
* The `help` symbol now correctly displays help for namespaced symbols.
* Enhanced the `tokenizer` symbol to provide additional information for symbols.
* Enhanced min shell highlighting to support dot notation, sigils, autopop.

