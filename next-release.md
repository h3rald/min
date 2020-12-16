* Added support for sigils on double-quoted strings.
* Added support for arbitrary strings as dictionary keys.
* Added **define-sigil**, **delete-sigil**, **seal-sigil**, **unseal-sigil**, **defined-sigil?**.
* Fixed behavior of **semver-inc-mahor** and **semver-inc-minor** to set lower digits to zero.
* Now using OpenSSL for all hashing symbols in the crypto module.
* Added **md4** symbol.
* Re-added the possibility to exclude OpenSSL by not defining the **ssl** flag.
* Added **clear** symbol to clear the screen.
* Added the **mapkey** and the **unmapkey** symbols to configure key mappings.
