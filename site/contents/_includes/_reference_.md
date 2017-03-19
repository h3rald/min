{@ _defs_.md || 0 @}

min includes a small but powerful standard library organized into the following _modules_:

{#link-module||lang#}
: Defines the basic language constructs, such as control flow, symbol definition and binding, exception handling, basic stack operators, etc.
{#link-module||io#}
: Provides operators for reading and writing files as well as printing to STDOUT and reading from STDIN.
{#link-module||fs#}
: Provides operators for accessing file information and properties. 
{#link-module||logic#}
: Provides comparison operators for all min data types and other boolean logic operators.
{#link-module||str#}
: Provides operators to perform operations on strings, use regular expressions, and convert strings into other data types.
{#link-module||sys#}
: Provides operators to use as basic shell commands, access environment variables, and execute external commands.
{#link-module||num#}
: Provides operators to perform simple mathematical operations on integer and floating point numbers.
{#link-module||time#}
: Provides a few basic operators to manage dates, times, and timestamps.
{#link-module||crypto#}
: Provides operators to compute hashes (MD5, SHA1, SHA224, SHA256, SHA384, sha512), base64 encoding/decoding, and AES encryption/decryption.

## Notation

The following notation is used in the signature of all min operators:

\*
: Any value.
B
: A boolean value.
{{q}}
: A quotation.
{{1}}
: The first quotation on the stack.
{{2}}
: The second quotation on the stack.
{{e}}
: An error dictionary:
  <pre><code>(
    (error "MyError")
    (message "An error occurred")
    (symbol "symbol1")            ;Optional
    (filename "dir1/file1.min")   ;Optional
    (line 3)                      ;Optional
    (column 13)                   ;Optional
  )
  </code></pre>
{{s}}
: A string value.
{{sp}}
: One or more string values.
{{sl}}
: String-like (a string or quoted sumbol).
{{f}}
: false (boolean type).
{{t}}
: true (boolean type).
{{null}}
: No value.
