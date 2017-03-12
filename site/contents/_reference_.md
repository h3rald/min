# Notation

{@ _defs_.md || 0 @}

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
S+
: One or more string values.
{{sl}}
: String-like (a string or quoted sumbol).
{{f}}
: false (boolean type).
{{t}}
: true (boolean type).
{{null}}
: No value.
