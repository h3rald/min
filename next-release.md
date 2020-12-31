* **REMOVED** support for creating dynamic libraries (it never worked properly anyway)
* Added **operator** symbol to define symbols and sigils in a more controlled way.
* Added **expect-all** and **expect-any** symbols.
* Fixed behavior of **require** and **invoke** ensuring that operators are evaluated in the correct scopes.
* Improved diagnostics of exceptions occurring in native code.
* Fixed unwanted stack pollution in **to-yaml** operator.
* Added check to prevent required modules from polluting the stack.
- Added **nossl** flag to compile without openssl (otherwise enabled by default).
