{@ _defs_.md || 0 @}

min includes a small but powerful standard library organized into the following _modules_:

{#link-module||lang#}
: Defines the basic language constructs, such as control flow, symbol definition and binding, exception handling,  etc.
{#link-module||stack#}
: Defines combinators and stack-shufflers like dip, dup, swap, cons, etc.
{#link-module||seq#}
: Defines operators for quotations and dictionaries, like map, filter, reduce, etc.
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

### Types and Values

{{null}}
: No value.
{{any}}
: A value of any type.
{{b}}
: A boolean value
{{i}}
: An integer value.
{{flt}}
: A float value.
{{n}}
: A numeric (integer or float) value.
{{s}}
: A string value.
{{sl}}
: A string-like value (string or quoted symbol).
{{q}}
: A quotation (also expressed as parenthesis enclosing other values).
{{d}}
: A dictionary value.
{{tinfo}}
: A timeinfo dictionary:
  <pre><code>(
    ("year" 2017)
    ("month" 7)
    ("day" 8)
    ("weekday" 6)
    ("yearday" 188)
    ("hour" 15)
    ("minute" 16)
    ("second" 25)
    ("dst" true)
    ("timezone" -3600)
  )
  </code></pre>
{{e}}
: An error dictionary:
  <pre><code>(
    ("error" "MyError")
    ("message" "An error occurred")
    ("symbol" "symbol1")
    ("filename" "dir1/file1.min")
    ("line" 3)
    ("column" 13)
  )
  </code></pre>
{{t}}
: true (boolean type).
{{f}}
: false (boolean type)

### Suffixes

The following suffixes can be placed at the end of a value or type to indicate ordering or quantities.

{{1}}
: The first value of the specified type.
{{2}}
: The second value of the specified type.
{{3}}
: The third value of the specified type.
{{4}}
: The fourth value of the specified type.
{{01}}
: Zero or one.
{{0p}}
: Zero or more.
{{1p}}
: One or more
