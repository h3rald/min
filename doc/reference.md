## Reference

{#op -> 
#### $1

_Signature:_ [ $2 **&rArr;** $3](class:kwd)

$4

 #}

### Notation

\*
: Any value.
B
: A boolean value.
{{q -> [(\*)](class:kwd)}}
: A quotation.
{{1 -> [(1)](class:kwd)}}
: The first quotation on the stack.
{{2 -> [(2)](class:kwd)}}
: The second quotation on the stack.
{{e -> [(E)](class:kwd)}}
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
{{s -> [S](class:kwd)}}
: A string value.
S+
: One or more string values.
{{sl -> [§](class:kwd)}}
: String-like (a string or quoted sumbol).
{{f -> [false](class:kwd)}} 
: false (boolean type).
{{t -> [true](class:kwd)}}
: true (boolean type).
{{null -> &#x2205;}}
: No value.

### `lang` Module

{#op||bind||\* §||{{null}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

{#op||call||(\*) §||\*?||
Calls operator {{sl}} defined in scope {{q}}. #}

{#op||debug||{{null}}||{{null}}||
Toggles debug mode. #}

{#op||debug?||{{null}}||B||
Returns {{t}} if debug mode is on, {{f}} otherwise. #}

{#op||define||\* §||{{null}}||
Defines a new symbol {{sl}}, containing the specified value (auto-quoted).#}

{#op||delete||§||{{null}}||
Deletes the specified symbol {{sl}}.#}

{#op||eval||S||\*?||
Parses and interprets {{s}}. #}

{#op||exit||{{null}}||{{null}}||
Exits the program or shell. #}

{#op||format-error||(E)||S||
Formats the error {{e}} as a string.

> %sidebar%
> Example
> 
> The following: 
> 
> `((error "MyError") (message "This is a test error")) format-error`
> 
> produces: `"(!) This is a test error"`
#}

{#op||from-json||S||\*||
Converts a JSON string into {{M -> MiNiM}} data.#}

{#op||import||§||{{null}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

{#op||inspect||(\*)||(S+)||
Returns a list of symbols published on {{q}}'s scope. #}

{#op||load||S||\*?||
Parses and interprets the specified {{M}} file {{s}}, adding [.min](class:ext) if not specified. #}

{#op||module||(\*) §||{{null}}||
Creates a new module {{sl}} based on quotation {{q}}. #}

{#op||publish||§ (*)||{{null}}||
Publishes symbol {{sl}} to the scope of [(\*)](class:kwd).

> %sidebar%
> Example
>
> Publish symbol [my-local-symbol](class:kwd) to [ROOT](class:kwd) scope:
> `'my-local-symbol ROOT publish`

#}

{#op||raise||(E)||{{null}}||
Raises the error specified via the dictionary {{e}}.#}


{#op||sigils||{{null}}||(S+)||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||source||§||(\*)||
Display the source code of symbol {{sl}} (if it has been implemented a {{M}} quotation). #}

{#op||symbols||{{null}}||(S+)||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

{#op||to-json||(\*)||S||
Converts a quotation into a JSON string {{s}}.#}

{#op||with||(2) (1)||\*?||
Applies quotation [(2)](class:kwd) within the scope of [(1)](class:kwd). #}

### `io` Module

### `fs` Module

### `sys` Module

### `str` Module

### `logic` Module

### `num` Module

### `time` Module

### `crypto` Module
