-----
content-type: "page"
title: "global Module"
-----
{@ _defs_.md || 0 @}

{#op||!=||{{a1}} {{a2}}||{{b}}||
Returns {{t}} if {{a1}} is not equal to {{a2}}, {{f}} otherwise. #}

{#sig||$||get-env#}

{#alias||$||get-env#}

{#alias||%||interpolate#}

{#alias||&&||expect-all#}

{#sig||&apos;||quotesym#}

{#alias||&apos;||quotesym#}

{#op||&ast;||{{n1}} {{n2}}||{{n3}}||
Multiplies {{n1}} by {{n2}}. #}

{#op||+||{{n1}} {{n2}}||{{n3}}||
Sums {{n1}} and {{n2}}. #}

{#op||-||{{n1}} {{n2}}||{{n3}}||
Subtracts {{n2}} from {{n1}}. #}

{#alias||->||dequote#}

{#op||-inf||{{none}}||{{n}}||
Returns negative infinity. #}

{#op||/||{{n1}} {{n2}}||{{n3}}||
Divides {{n1}} by {{n2}}. #}

{#sig||:||define#}

{#alias||:||define#}

{#alias||::||operator#}

{#op||&lt;||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is smaller than {{a2}}, {{f}} otherwise. 
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#op||&lt;=||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is smaller than or equal to {{a2}}, {{f}} otherwise.
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#alias||=%||apply-interpolate#}

{#alias||=-=||expect-empty-stack#}

{#op||==||{{a1}} {{a2}}||{{b}}||
Returns {{t}} if {{a1}} is equal to {{a2}}, {{f}} otherwise. #}

{#op||==&gt;||{{none}}||{{none}}||
Symbol used to separate input and output values in operator signatures.#}

{#alias||=&gt;||apply#}

{#op||&gt;||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is greater than {{a2}}, {{f}} otherwise. 
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#alias||&gt;&lt;||infix-dequote#}

{#op||&gt;=||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is greater than or equal to {{a2}}, {{f}} otherwise.
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#alias||&gt;&gt;||prefix-dequote#}

{#sig||?||help#}

{#alias||?||help#}

{#sig||@||bind#}

{#alias||@||bind#}

{#sig||^||lambda#}

{#alias||^||lambda#}

{#op||all?||{{q1}} {{q2}}||{{b}}||
Applies predicate {{q2}} to each element of {{q1}} and returns {{t}} if all elements of {{q1}} satisfy predicate {{q2}}, {{f}} otherwise. #}

{#op||and||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} is equal to {{b2}}, {{f}} otherwise.#}

{#op||any?||{{q1}} {{q2}}||{{b}}||
Applies predicate {{q2}} to each element of {{q1}} and returns {{t}} if at least one element of {{q1}} satisfies predicate {{q2}}, {{f}} otherwise. #}

{#op||append||{{any}} {{q}}||({{a0p}} {{any}})||
Returns a new quotation containing the contents of {{q}} with {{any}} appended. #}

{#op||apply||{{q}}||({{a0p}})||
Returns a new quotation obtained by evaluating each element of {{q}} in a separate stack. #}

{#op||apply-interpolate||{{s}} {{q}}||{{s}}||
The same as pushing `apply` and then `interpolate` on the stack.#}

{#op||args||{{none}}||{{q}}||
Returns a list of all arguments passed to the current program.#}

{#op||avg||{{q}}||{{n}}||
Returns the average of the items of {{q}}. #}

{#op||base||[&quot;dec&quot;&#124;&quot;hex&quot;&#124;&quot;oct&quot;&#124;&quot;bin&quot;](class:kwd)||{{none}}||
Sets the numeric base used to represent integers. #}

{#op||base?||{{none}}||[&quot;dec&quot;&#124;&quot;hex&quot;&#124;&quot;oct&quot;&#124;&quot;bin&quot;](class:kwd)||
Returns the numeric base currently used to represent integers (default: [&quot;dec&quot;](class:kwd)). #}

{#op||bind||{{any}} {{sl}}||{{none}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

{#op||bitand||{{i1}} {{i2}}||{{i3}}||
Computes the bitwise *and* of integer {{i1}} and {{i2}}.#}

{#op||bitclear||{{i1}} {{q}}||{{i2}}||
Sets the bytes specified via their position in {{i1}} through {{q}} to 0. #}

{#op||bitflip||{{i1}} {{q}}||{{i2}}||
Flips the bytes specified via their position in {{i1}} through {{q}}. #}

{#op||bitnot||{{i1}}||{{i2}}||
Computes the bitwise *complement* of {{i1}}.#}

{#op||bitor||{{i1}} {{i2}}||{{i3}}||
Computes the bitwise *or* of integers {{i1}} and {{i2}}.#}

{#op||bitparity||{{i1}}||{{i2}}||
Calculate the bit parity in {{i1}}. If the number of 1-bits is odd, the parity is 1, otherwise 0.#}

{#op||bitset||{{i1}} {{q}}||{{i2}}||
Sets the bytes specified via their position in {{i1}} through {{q}} to 0. #}

{#op||bitxor||{{i1}} {{i2}}||{{i3}}||
Computes the bitwise *xor* of integers {{i1}} and {{i2}}.#}

{#op||boolean||{{any}}||{{b}}||
> Converts {{any}} to a boolean value based on the following rules:
> 
>  * If {{any}} is a boolean value, no conversion is performed.
>  * If {{any}} is {{null}}, it is converted to {{f}}.
>  * If {{any}} is a numeric value, zero is converted to {{f}}, otherwise it is converted to {{t}}.
>  * If {{any}} is a quotation or a dictionary, the empty quotation or dictionary is converted to {{f}}, otherwise it is converted to {{t}}.
>  * If {{any}} is a string, the empty string, and `"false"` are converted to {{f}}, otherwise it is converted to {{t}}.#}

{#op||boolean?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a boolean, {{f}} otherwise. #}

{#op||capitalize||{{sl}}||{{s}}||
Returns a copy of {{sl}} with the first character capitalized.#}

{#op||case||(({{q1}} {{q2}}){{0p}})||{{a0p}}||
> This operator takes a quotation containing _n_ different conditional branches. 
> 
> Each branch must be a quotation containing two quotations, and it is processed as follows:
> 
>   * if {{q1}} evaluates to {{t}}, then the {{q2}} is executed.
>   * if {{q1}} evaluates to {{f}}, then the following branch is processed (if any).
> 
> > %sidebar%
> > Example
> > 
> > The following program prints "Smaller than 3":
> > 
> >     (
> >        ((2 > 3) ("Greater than 3" put!))
> >        ((2 < 3) ("Smaller than 3" put!))
> >        ((true) ("Exactly 3" put!))
> >     ) case #}

{#op||chr||{{i}}||{{s}}||
Returns the single character {{s}} obtained by interpreting {{i}} as an ASCII code.#}

{#op||compiled?||{{none}}||{{b}}||
Returns {{t}} if the current program has been compiled.#}

{#op||concat||{{q1}} {{q2}}||{{q3}}||
Concatenates {{q1}} with {{q2}}. #}

{#op||decode-url||{{sl}}||{{s}}||
URL-decodes {{sl}}, deconding all URL-encoded characters.#}

{#op||define||{{any}} {{sl}}||{{none}}||
Defines a new symbol {{sl}}, containing the specified value.#}

{#op||define-sigil||{{any}} {{sl}}||{{none}}||
Defines a new sigil {{sl}}, containing the specified value (auto-quoted if not already a quotation).#}

{#op||defined-symbol?||{{sl}}||{{b}}||
Returns {{t}} if the symbol {{sl}} is defined, {{f}} otherwise.#}

{#op||defined-sigil?||{{sl}}||{{b}}||
Returns {{t}} if the symbol {{sl}} is defined, {{f}} otherwise.#}

{#op||delete-sigil||{{sl}}||{{none}}||
Deletes the specified user-defined sigil {{sl}}.#}

{#op||delete-symbol||{{sl}}||{{none}}||
Deletes the specified symbol {{sl}}.#}

{#op||dequote||{{q}}||{{a0p}}||
> Pushes the contents of quotation {{q}} on the stack.
>
> Each element is pushed on the stack one by one. If any error occurs, {{q}} is restored on the stack.#}

{#op||dev||{{none}}||{{none}}||
Toggles development mode.#}

{#op||dev?||{{none}}||{{b}}||
Returns {{t}} if the current program is being executed in development mode.#}

{#op||dictionary?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a dictionary, {{f}} otherwise. #}

{#op||difference||{{q1}} {{q2}}||{{q3}}||
> Calculates the difference {{q3}} of {{q1}} and {{q2}}.
>
> > %sidebar%
> > Example
> > 
> > The following program leaves `(2)` on the stack:
> > 
> >     (1 2 "test") ("test" "a" true 1) seq.difference #}

{#op||div||{{i1}} {{i2}}||{{i3}}||
Divides {{i1}} by {{i2}} (integer division). #}

{#op||drop||{{q1}} {{i}}||{{q2}}||
Returns a quotation {{q2}} containing the remaining elements after the first _n_ values of the input quotation {{q1}}, or an empty quotation if {{i}} is greater than the length of {{q1}}. #}

{#op||encode-url||{{sl}}||{{s}}||
URL-encodes {{sl}}, encoding all special characters into URL-encoded characters.#}

{#op||escape||{{sl}}||{{s}}||
Returns a copy of {{sl}} with quotes and backslashes escaped with a backslash.#}

{#op||eval||{{s}}||{{a0p}}||
Parses and interprets {{s}}. #}

{#op||even?||{{i}}||{{b}}||
Returns {{t}} if {{i}} is even, {{f}} otherwise. #}

{#op||exit||{{i}}||{{none}}||
Exits the program or shell with {{i}} as return code. #}

{#op||expect||{{q1}}||{{q2}}||
> If the `-d` (`--dev`) flag is specified when running the program, validates the first _n_ elements of the stack against the type descriptions specified in {{q1}} (_n_ is {{q1}}'s length) and if all the elements are valid returns them wrapped in {{q2}} (in reverse order). If the `-d` (`--dev`) flag is not specified when running the program, no validation is performed and all elements are just returned in a quotation in reverse order. 

> > %tip%
> > Tips
> > 
> > * You can specify a typed dictionary by prepending the type name with `dict:`. Example: `dict:socket`
> > * You can specify two or more matching types by separating combined together in a logical type expression, e.g.: `string|quot`

> > %sidebar%
> > Example
> > 
> > Assuming that the following elements are on the stack (from top to bottom): 
> > 
> > `1 "test" 3.4`
> > 
> > the following program evaluates to `true`:
> > 
> > `(int string num) expect (3.4 "test" 1) ==`#}

{#op||expect-all||{{q}}||{{b}}||
Assuming that {{q}} is a quotation of quotations each evaluating to a boolean value, it pushes {{t}} on the stack if they all evaluate to {{t}}, {{f}} otherwise.
 #}
 
{#op||expect-any||{{q}}||{{b}}||
Assuming that {{q}} is a quotation of quotations each evaluating to a boolean value, it pushes {{t}} on the stack if any evaluates to {{t}}, {{f}} otherwise.
 #}

{#op||expect-empty-stack||{{none}}||{{none}}||
Raises an error if the stack is not empty.#}

{#op||filter||{{q1}} {{q2}}||{{q3}}||
> Returns a new quotation {{q3}} containing all elements of {{q1}} that satisfy predicate {{q2}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `(2 6 8 12)` on the stack:
> > 
> >     (1 37 34 2 6 8 12 21) 
> >     (stackdup 20 < stack.swap even? and) seq.filter #}

{#op||find||{{q1}} {{q2}}||{{i}}||
> Returns the index of the first element within {{q1}} that satisfies predicate {{q2}}, or -1 if no element satisfies it.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `3` on the stack:
> > 
> >     (1 2 4 8 16) 
> >     (5 >) seq.find #}

{#op||first||{{q}}||{{any}}||
Returns the first element of {{q}}. #}

{#op||flatten||{{q1}}||{{q2}}||
> Flattens all quotations within {{q1}} and returns the resulting sequence {{q2}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 2 3 4 5 6 7 8)` on the stack:
> > 
> >     (1 (2 3 4) 5 (6 7) 8) 
> >     seq.flatten #}

{#op||float||{{any}}||{{flt}}||
> Converts {{any}} to a float value based on the following rules:
> 
>   * If {{any}} is {{t}}, it is converted to `1.0`.
>   * If {{any}} is {{f}}, it is converted to `0.0`.
>   * If {{any}} is {{null}}, it is converted to `0.0`.
>   * If {{any}} is a integer, it is converted to float value.
>   * If {{any}} is a float, no conversion is performed.
>   * If {{any}} is a string, it is parsed as a float value.#}

{#op||float?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a float, {{f}} otherwise. #}

{#op||foreach||{{q1}} {{q2}}||{{a0p}}||
Applies the quotation {{q2}} to each element of {{q1}}.#}

{#op||format-error||{{e}}||{{s}}||
> Formats the error {{e}} as a string. 
> > %sidebar%
> > Example
> > 
> > The following code: 
> > 
> >      (
> >        (
> >           {"MyError" :error "This is a test error" :message} raise
> >        ) 
> >        (format-error)
> >      ) try
> > 
> > produces: `"This is a test error"`#}

{#op||from-bin||{{sl}}||{{i}}||
Parses {{sl}} as a binary number. #}

{#op||from-dec||{{sl}}||{{i}}||
Parses {{sl}} as a decimal number. #}

{#op||from-hex||{{sl}}||{{i}}||
Parses {{sl}} as a hexadecimal number. #}

{#op||from-json||{{s}}||{{any}}||
Converts a JSON string into {{m}} data.#}

{#op||from-oct||{{sl}}||{{i}}||
Parses {{sl}} as a octal number. #}

{#op||from-semver||{{s}}||{{d}}||
Given a basic [SemVer](https://semver.org)-compliant string (with no additional labels) {{s}}, 
it pushes a dictionary {{d}} on the stack containing a **major**, **minor**, and **patch** key/value pairs.#}

{#op||from-yaml||{{s}}||{{any}}||
> Converts a YAML string into {{m}} data.
> > %note%
> > Note
> > 
> > At present, only YAML objects containing string values are supported.#}

{#op||get||{{q}} {{i}}||{{any}}||
Returns the _n^th_ element of {{q}} (zero-based).#}

{#op||gets||{{none}}||{{s}}||
Reads a line from STDIN and places it on top of the stack as a string.#}

{#op||get-env||{{sl}}||{{s}}||
Returns environment variable {{sl}}. #}

{#op||harvest||{{q1}}||{{q2}}||
> Creates a new quotation {{q2}} containing all elements of {{q1}} except for empty quotations.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 2 3)` on the stack:
> > 
> >     (1 () () () 2 () 3) 
> >     seq.harvest #}

{#op||help||{{sl}}||{{none}}||
Prints the help text for {{sl}}, if available. #}

{#op||if||{{q1}} {{q2}} {{q3}}||{{a0p}}||
If {{q1}} evaluates to {{t}} then evaluates {{q2}}, otherwise evaluates {{q3}}.#}

{#op||import||{{sl}}||{{none}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

{#op||in?||{{q}} {{any}}||{{b}}||
Returns {{t}} if {{any}} is contained in {{q}}, {{f}} otherwise.#}

{#op||indent||{{sl}} {{i}}||{{s}}||
Returns {{s}} containing {{sl}} indented with {{i}} spaces.#}

{#op||indexof||{{s1}} {{s2}}||{{i}}||
If {{s2}} is contained in {{s1}}, returns the index of the first match or -1 if no match is found. #}

{#op||inf||{{none}}||{{n}}||
Returns infinity. #}

{#op||infix-dequote||{{q}}||{{any}}||
> Dequotes {{q}} using infix notation. 
> 
> Note that no special operator preference is defined, symbols precedence is always left-to-right. However, you can use parentheses (quotes) to evaluate expressions before others.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `17` on the stack:
> >
> >      (2 + (3 * 5)) infix-dequote
> >
> > while this program leaves `25` on the stack:
> > 
> >      (2 + 3 * 5) infix-dequote  
 #}

{#op||insert||{{q1}} {{any}} {{i}}||{{q2}}||
Inserts {{any}} as the value of the _n^th_ element {{q1}} (zero-based), and returns the modified copy of the quotation {{q2}}. #}

{#op||integer||{{any}}||{{i}}||
> Converts {{any}} to an integer value based on the following rules:
> 
>   * If {{any}} is {{t}}, it is converted to `1`.
>   * If {{any}} is {{f}}, it is converted to `0`.
>   * If {{any}} is {{null}}, it is converted to `0`.
>   * If {{any}} is an integer, no conversion is performed.
>   * If {{any}} is a float, it is converted to an integer value by truncating its decimal part.
>   * If {{any}} is a string, it is parsed as an integer value.#}

{#op||integer?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is an integer, {{f}} otherwise. #}

{#op||interpolate||{{s}} {{q}}||{{s}}||
> Substitutes the placeholders included in {{s}} with the values in {{q}}.
> > %note%
> > Notes
> > 
> > * If {{q}} contains symbols or quotations, they are not interpreted. To do so, call `apply` before interpolating or use `apply-interpolate` instead.
> > * You can use the `$#` placeholder to indicate the next placeholder that has not been already referenced in the string.
> > * You can use named placeholders like `$pwd`, but in this case {{q}} must contain a quotation containing both the placeholder names (odd items) and the values (even items).
> 
> > %sidebar%
> > Example
> >  
> > The following code (executed in a directory called '/Users/h3rald/Development/min' containing 19 files):
> > 
> > `"Directory '$1' includes $2 files." (sys.pwd (sys.pwd sys.ls 'fs.file? seq.filter size)) apply interpolate`
> > 
> > produces:
> > 
> > `"Directory '/Users/h3rald/Development/min' includes 19 files."`#}
 
{#op||intersection||{{q1}} {{q2}}||{{q3}}||
> Calculates the intersection {{q3}} of {{q1}} and {{q2}}.
>
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 "test")` on the stack:
> > 
> >     (1 2 "test") ("test" "a" true 1) seq.intersection #}

{#op||join||{{q}} {{sl}}||{{s}}||
Joins the elements of {{q}} using separator {{sl}}, producing {{s}}.#}

{#op||lambda||{{q}} {{sl}}||{{none}}||
> Defines a new symbol {{sl}}, containing the specified quotation {{q}}. Unlike with `define`, in this case {{q}} will not be quoted, so its values will be pushed on the stack when the symbol {{sl}} is pushed on the stack.
> 
> Essentially, this symbol allows you to define an operator without any validation of constraints and bind it to a symbol.#}

{#op||lambda-bind||{{q}} {{sl}}||{{none}}||
Binds the specified quotation to an existing symbol {{sl}} which was previously-set via `lambda`. #}

{#op||last||{{q}}||{{any}}||
Returns the last element of {{q}}. #}

{#op||length||{{sl}}||{{i}}||
Returns the length of {{sl}}.#}

{#op||line-info||{{none}}||{{d}}||
Returns a dictionary {{d}} containing a **filename**, **line**, and **column** properties identifying the filename, line and column of the current symbol.#}

{#op||linrec||{{q1}} {{q2}} {{q3}} {{q4}}||{{a0p}}||
> Implements linear recursions as follows:
> 
>   1. Evaluates {{q1}}.
>     * If {{q1}} evaluates to {{t}}, then it evaluates {{q2}}.
>     * Otherwises it executes {{q3}} and recurses using the same four quotations.
>   2. Finally, it executes {{q4}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `120` on the stack, the factorial of 5:
> > 
> >      5 (dup 0 ==) 'succ (dup pred) '* linrec
 #}

{#op||load||{{sl}}||{{a0p}}||
Parses and interprets the specified {{m}} file {{sl}}, adding [.min](class:ext) if not specified. #}

{#op||load-symbol||{{sl}}||{{a0p}}||
Loads the contents of symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||loglevel||{{sl}}||{{none}}||
> Sets the current logging level to {{sl}}. {{sl}} must be one of the following strings or quoted symbols:
> 
>   * debug
>   * info
>   * notice
>   * warn
>   * error
>   * fatal
> 
> > %note%
> > Note
> > 
> > The default logging level is _notice_.#}

{#op||loglevel?||{{none}}||{{s}}||
Returns the current log level (debug, info, notice, warn, error or fatal). #}

{#op||lowercase||{{sl}}||{{s}}||
Returns a copy of {{sl}} converted to lowercase.#}

{#op||map||{{q1}} {{q2}}||{{q3}}||
Returns a new quotation {{q3}} obtained by applying {{q2}} to each element of {{q1}}.#}

{#op||map-reduce||{{q1}} {{q2}} {{q3}}||{{i}}||
> Applies {{q2}} (map) to each element of {{q1}} and then applies {{q3}} (reduce) to each successive element of {{q1}}. {{q1}} must have at least one element.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `35` on the stack:
> > 
> >     (1 3 5) 
> >     (stack.dup *) (+) seq.map-reduce #}

{#op||match?||{{s1}} {{s2}}||{{b}}||
> Returns {{t}} if {{s2}} matches {{s1}}, {{f}} otherwise.
> > %tip%
> > Tip
> > 
> > {{s2}} is a {{pcre}}#}.

{#op||med||{{q}}||{{n}}||
Returns the median of the items of {{q}}. #}

{#op||mod||{{i1}} {{i2}}||{{i3}}||
Returns the integer module of {{i1}} divided by {{i2}}. #}

{#op||nan||{{none}}||nan||
Returns **NaN** (not a number). #}

{#op||not||{{b1}}||{{b2}}||
Negates {{b1}}.#}

{#op||null?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is {{null}}, {{f}} otherwise. #}

{#op||number?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a number, {{f}} otherwise. #}

{#op||odd?||{{i}}||{{b}}||
Returns {{t}} if {{i}} is odd, {{f}} otherwise. #}

{#op||one?||{{q1}} {{q2}}||{{b}}||
Applies predicate {{q2}} to each element of {{q1}} and returns {{t}} if only one element of {{q1}} satisfies predicate {{q2}}, {{f}} otherwise. #}

{#op||operator||{{q}}||{{a0p}}||
> Provides a way to define a new operator (symbol, sigil, or typeclass) on the current scope performing additional checks (compared to `define` and `define-sigil`), and automatically mapping inputs and outputs.
> 
> {{q}} is a quotation containing:
> 
> * A symbol identifying the type of operator to define (`symbol`, `sigil`, or `typeclass`).
> * A symbol identifying the name of the operator.
> * A quotation defining the signature of the operator, containing input and output values identified by their type and a capturing symbol, separated by the `==>` symbol.
> * A quotation identifying the body of the operator.
>
> The main additional features offered by this way of defining operators are the following:
>
> * If in development mode (`-d` or `--dev` flag specified at run time), both input and output values are checked against a type (like when using the `expect` operator *and* automatically captured in a symbol that can be referenced in the operator body quotation.
> * The full signature of the operator is declared, making the resulting code easier to understand at quick glance.
> * An exception is automatically raised if the operator body pollutes the stack by adding or removing elements from the stack (besides adding the declared output values).
> * It is possible to use the `return` symbol within the body quotation to immediately stop the evaluation of the body quotation and automatically push the output values on the stack.
> 
> > %sidebar%
> > Example
> > 
> > The following program defines a `pow` operator that calculates the power of a number providing its base and exponent, and handling some NaN results using the `return` symbol:
> >
> >      (
> >        symbol pow
> >        (num :base int :exp ==> num :result)
> >        ( 
> >          (base 0 == exp 0 == and)
> >            (nan @result return)
> >          when
> >          (base 1 == exp inf == and)
> >            (nan @result return)
> >          when
> >          (base inf == exp 0 == and)
> >            (nan @result return)
> >          when
> >          exp 1 - :n
> >          base  (dup) n times (*) n times @result
> >        )
> >      ) ::
 #}

{#op||opts||{{none}}||{{d}}||
Returns a dictionary of all options passed to the current program, with their respective values.#}

{#op||or||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} or {{b2}} is {{t}}, {{f}} otherwise.#}

{#op||ord||{{s}}||{{i}}||
Returns the ASCII code {{i}} corresponding to the single character {{s}}.#}

{#op||parent-scope||{{d1}}||{{d2}}||
Returns a dictionary {{d2}} holding a reference to the parent scope of {{d1}} or {{null}} if {{d1}} is global.#}

{#op||parse||{{s}}||{{q}}||
Parses {{s}} and returns a quoted program {{q}}. #}

{#op||parse-url||{{s}}||{{url}}||
Parses the url {{s}} into its components and stores them into {{url}}.#} 

{#op||partition||{{q1}} {{q2}}||{{q3}} {{q4}}||
> Partitions {{q1}} into two quotations: {{q3}} contains all elements of {{q1}} that satisfy predicate {{q2}}, {{q4}} all the others.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 3 5) (2 4 6)` on the stack:
> > 
> >     (1 2 3 4 5 6) 
> >     (odd?) seq.partition #}

{#op||pred||{{i1}}||{{i2}}||
Returns the predecessor of {{i1}}.#}

{#op||prefix||{{sl1}} {{sl2}}||{{s}}||
Prepends {{sl2}} to {{sl1}}.#}

{#op||prefix-dequote||{{q}}||{{any}}||
> Dequotes {{q}} using prefix notation (essentially it reverses {{q}} and dequotes it).
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `4` on the stack:
> >
> >     (* 8 4) prefix-dequote
 #}

{#op||prepend||{{any}} {{q}}||({{any}} {{a0p}})||
Returns a new quotation containing the contents of {{q}} with {{any}} prepended. #}

{#op||print||{{any}}||{{any}}||
Prints {{any}} to STDOUT.#}

{#op||product||{{q}}||{{i}}||
Returns the product of all items of {{q}}. {{q}} is a quotation of integers. #}

{#op||prompt||{{none}}||{{s}}||
> This symbol is used to configure the prompt of the min shell. By default, it is set to the following quotation:
> 
>     ("[$1]$$ " (sys.pwd) => %)

{#op||publish||{{sl}} {{d}}||{{none}}||
> Publishes symbol {{sl}} to the scope of {{d}}.
> 
> > %sidebar%
> > Example
> > 
> Publish symbol [my-local-symbol](class:kwd) to [global](class:kwd) scope:
> > `'my-local-symbol global publish` #}

{#op||put-env||{{sl1}} {{sl2}}||{{s}}||
Sets environment variable {{sl2}} to {{sl1}}. #}

{#op||puts||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT.#}

{#op||quit||{{none}}||{{none}}||
Exits the program or shell with 0 as return code. #}

{#op||quotation?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a quotation, {{f}} otherwise. #}

{#op||quote||{{any}}||({{any}})||
Wraps {{any}} in a quotation. #}

{#op||quote-map||{{q1}}||{{q2}}||
Returns a new quotation {{q2}} obtained by quoting each element of {{q1}}.#}

{#op||quotecmd||{{s}}||({{sym}})||
Creates a command with the value of {{s}} and wraps it in a quotation. #}

{#op||quoted-symbol?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a quoted symbol, {{f}} otherwise. #}

{#op||quotesym||{{s}}||({{sym}})||
Creates a symbol with the value of {{s}} and wraps it in a quotation. #}

{#op||raise||{{e}}||{{none}}||
Raises the error specified via the dictionary {{e}}.#}

{#op||raw-get||{{q}} {{i}}||{{rawval}}||
Returns the _n^th_ element of {{q}} (zero-based) wrapped in a {{rawval}}.#}

{#op||random||{{i1}}||{{i2}}||
> Returns a random number {{i2}} between 0 and {{i1}}-1. 
> 
> > %note%
> > Note
> > 
> > You must call `randomize` to initialize the random number generator, otherwise the same sequence of numbers will be returned.#}

{#op||randomize||{{none}}||{{null}||
Initializes the random number generator using a seed based on the current timestamp. #}

{#op||range||{{q2}}||{{q2}}||
Takes a quotation {{q1}} of two or three integers in the form of *start*, *end* and an optional *step* (1 if not specified) and generates the sequence and returns the resulting quotation of integers {{q2}}. #}

{#op||raw-args||{{none}}||{{q}}||
Returns a list of all arguments and (non-parsed) options passed to the current program.#}

{#op||reduce||{{q1}} {{a1}} {{q2}}||{{a2}}||
> Combines each successive element of {{q1}} using {{q2}}. On the first iteration, the first two inputs processed by {{q2}} are {{a1}} and the first element of {{q1}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `120` on the stack:
> > 
> >     (1 2 3 4 5) 
> >     1 (*) seq.reduce #}

{#op||reject||{{q1}} {{q2}}||{{q3}}||
Returns a new quotatios {{q3}} including all elements of {{q1}} that do not satisfy predicate {{q2}} (i.e. the opposite of `filter`)#}

{#op||remove||{{q1}} {{i}}||{{q2}}||
Returns the _n^th_ element of {{q1}} (zero-based), and returns the modified copy of the quotation {{q2}}.#}

{#op||remove-symbol||{{sl}}||{{none}}||
Removes the symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||repeat||{{sl}} {{i}}||{{s}}||
Returns {{s}} containing {{sl}} repeated {{i}} times.#}

{#op||replace||{{s1}} {{s2}} {{s3}}||{{s4}}||
> Returns a copy of {{s1}} containing all occurrences of {{s2}} replaced by {{s3}}
> > %tip%
> > Tip
> > 
> > {{s2}} is a {{pcre}}.
> 
> > %sidebar%
> > Example
> > 
> > The following:
> > 
> > `"This is a stupid test. Is it really a stupid test?" " s[a-z]+" " simple" replace`
> > 
> > produces:
> > 
> > `"This is a simple test. Is it really a simple test?"`#}

{#op||replace-apply||{{s1}} {{s2}} {{q}}||{{s3}}||
> Returns a copy of {{s1}} containing all occurrences of {{s2}} replaced by applying {{q}} to each quotation corresponding to each match.
> > %tip%
> > Tip
> > 
> > {{s2}} is a {{pcre}}.
> 
> > %sidebar%
> > Example
> > 
> > The following:
> > 
> > `":1::2::3::4:" ":(\d):" (1 get :d "-$#-" (d) =%) replace-apply`
> > 
> > produces:
> > 
> > `"-1--2--3--4-"`
> > 
> > Note that for each match the following quotations (each containing the full match and the captured matches) are produced as input for the replace quotation: `("-1-" "1") ("-2-" "2") ("-3-" "3") ("-4-" "4")` #}

{#op||require||{{sl}}||{{d}}||
Parses and interprets (in a separated interpreter) the specified {{m}} module, and returns a module dictionary {{d}} containing all the symbols defined in {{sl}}. 

This symbol will attempt to locate the specified module in this way. Given the following {{m}} program:

     'my-module require :my-module

1. Check for a file named `my-module` in the same folder as the current file (with our without a `.min` extension).
2. Check for a file named `index.min` in the `mmm/my-module/*/index.min` folder relative to the current file (locally-installed [managed-module](/learn-mmm)).
3. Check for a file named `index.min` in the `$HOME/mmm/my-module/*/index.min` folder (globally-installed [managed-module](/learn-mmm)). If multiple versions of the same module are present, the first one will be loaded. #}

{#op||rest||{{q1}}||{{q2}}||
Returns a new quotation {{q2}} containing all elements of {{q1}} quotation except for the first. #}

{#op||return||{{none}}||{{none}}||
If used within the body quotation of an operator definition, causes the interpreter to stop pushing further body elements on the stack and start pushing tbe operator output values on the stack. 

If used outside of the body quotation of an operator definition, it raises an exception.#}

{#op||reverse||{{q1}}||{{q2}}||
Returns a new quotation {{q2}} containing all elements of {{q1}} in reverse order. #}

{#op||save-symbol||{{sl}}||{{none}}||
Saves the contents of symbol {{sl}} to the [.min\_symbols](class:file) file. #}

{#op||saved-symbols||{{none}}||({{s0p}})||
Returns a quotation containing all symbols saved in the [.min\_symbols](class:file) file. #}

{#op||scope||{{none}}||{{d}}||
> Returns a dictionary {{d}} holding a reference to the current scope.
>  
> This can be useful to save a reference to a given execution scope to access later on.
>
> > %sidebar%
> > Example
> > 
> > The following program leaves `{(2) :two ;module}` on the stack:
> > 
> >     {} :myscope (2 :two scope @myscope) ->
 #}

{#op||scope-sigils||{{d}}||({{s0p}})||
Returns a list of all sigils defined in dictionary {{d}}.#}

{#op||scope-symbols||{{d}}||({{s0p}})||
Returns a list of all symbols defined in dictionary {{d}}.#}

{#op||seal-symbol||{{sl}}||{{none}}||
Seals symbol {{sl}}, so that it cannot be re-assigned. #}

{#op||seal-sigil||{{sl}}||{{none}}||
Seals the user-defined sigil {{sl}}, so that it cannot be re-defined. #}

{#op||sealed-symbol?||{{sl}}||{{b}}||
Returns {{t}} if the symbol {{sl}} is sealed, {{f}} otherwise.#}

{#op||sealed-sigil?||{{sl}}||{{b}}||
Returns {{t}} if the sigil {{sl}} is sealed, {{f}} otherwise.#}

{#op||search||{{s1}} {{s2}}||{{q}}||
> Returns a quotation containing the first occurrence of {{s2}} within {{s1}}. Note that:
> 
>   * The first element of {{q}} is the matching substring.
>   * Other elements (if any) contain captured substrings.
>   * If no matches are found, the quotation contains empty strings.
> 
> > %tip%
> > Tip
> > 
> > {{s2}} is a {{pcre}}.
> 
> > %sidebar%
> > Example
> > 
> > The following:
> > 
> > `"192.168.1.1, 127.0.0.1" "[0-9]+\.[0-9]+\.([0-9]+)\.([0-9]+)" search`
> > 
> > produces: `("192.168.1.1", "1", "1")`#}

{#op||search-all||{{s1}} {{s2}}||{{q}}||
Returns a quotation of quotations (like the one returned by the search operator) containing all occurrences of {{s2}} within {{s1}}. #}

{#op||semver-inc-major||{{s1}}||{{s2}}||
Increments the major digit of the [SemVer](https://semver.org)-compliant string (with no additional labels) {{s1}}. #}

{#op||semver-inc-minor||{{s1}}||{{s2}}||
Increments the minor digit of the [SemVer](https://semver.org)-compliant string (with no additional labels) {{s1}}. #}

{#op||semver-inc-patch||{{s1}}||{{s2}}||
Increments the patch digit of the [SemVer](https://semver.org)-compliant string (with no additional labels) {{s1}}. #}

{#op||semver?||{{s}}||{{b}}||
Checks whether {{s}} is a [SemVer](https://semver.org)-compliant version or not. #}

{#op||set||{{q1}} {{any}} {{i}}||{{q2}}||
Sets the value of the _n^th_ element {{q1}} (zero-based) to {{any}}, and returns the modified copy of the quotation {{q2}}. #}

{#op||set-sym||{{q1}} {{sl}} {{i}}||{{q2}}||
Sets the value of the _n^th_ element {{q1}} (zero-based) to {{sl}} (treating it as a symbol), and returns the modified copy of the quotation {{q2}}. #}

{#op||shl||{{i1}} {{i2}}||{{i3}}||
Computes the *shift left* operation of {{i1}} and {{i2}}.#}

{#op||shorten||{{q1}} {{i}}||{{q2}}||
Returns a quotation {{q2}} containing the first _n_ values of the input quotation {{q1}}. #}

{#op||shr||{{i1}} {{i2}}||{{i3}}||
Computes the *shift right* operation of {{i1}} and {{i2}}.#}

{#op||sigil-help||{{sl}}||{{help}}|{{null}}||
Returns the help dictionary for the sigil {{sl}}, if available, {{null}} otherwise. #}

{#op||sigils||{{none}}||({{s0p}})||
Returns a list of all sigils defined in the [global](class:kwd) scope.#}

{#op||size||{{q}}||{{i}}||
Returns the length of {{q}}.#}

{#op||slice||{{q1}} {{i1}} {{i2}}||{{q2}}||
> Creates a new quotation {{q2}} obtaining by selecting all elements of {{q1}} between indexes {{i1}} and {{i2}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `(3 4 5)` on the stack:
> > 
> >     (1 2 3 4 5 6) 
> >     2 4 seq.slice #}

{#op||sort||{{q1}} {{q2}}||{{q3}}||
> Sorts all elements of {{q1}} according to predicate {{q2}}. 
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 3 5 7 9 13 16)` on the stack:
> > 
> >     (1 9 5 13 16 3 7) '> seq.sort #}

{#op||source||{{sl}}||{{q}}||
Display the source code of symbol {{sl}} (if it has been implemented a {{m}} quotation). #}

{#op||split||{{sl1}} {{sl2}}||{{q}}||
Splits {{sl1}} using separator {{sl2}} (a {{pcre}}) and returns the resulting strings within the quotation {{q}}. #}

{#op||string||{{any}}||{{s}}||
Converts {{any}} to its string representation.#}

{#op||string?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a string, {{f}} otherwise. #}

{#op||stringlike?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a string or a quoted symbol, {{f}} otherwise. #}

{#op||strip||{{sl}}||{{s}}||
Returns {{s}}, which is set to {{sl}} with leading and trailing spaces removed.#} 

{#op||substr||{{s1}} {{i1}} {{i2}}||{{s2}}||
Returns a substring {{s2}} obtained by retrieving {{i2}} characters starting from index {{i1}} within {{s1}}.#}

{#op||succ||{{i1}}||{{i2}}||
Returns the successor of {{i1}}.#}

{#op||suffix||{{sl1}} {{sl2}}||{{s}}||
Appends {{sl2}} to {{sl1}}.#}

{#op||sum||{{q}}||{{i}}||
Returns the sum of all items of {{q}}. {{q}} is a quotation of integers. #}

{#op||symbol-help||{{sl}}||{{help}}|{{null}}||
Returns the help dictionary for the symbol {{sl}}, if available, {{null}} otherwise. #}

{#op||symbols||{{none}}||({{s0p}})||
Returns a list of all symbols defined in the [global](class:kwd) scope.#}

{#op||symmetric-difference||{{q1}} {{q2}}||{{q3}}||
> Calculates the symmetric difference {{q3}} of {{q1}} and {{q2}}.
>
> > %sidebar%
> > Example
> > 
> > The following program leaves `(true "a" 2)` on the stack:
> > 
> >     (1 2 "test") ("test" "a" true 1) seq.symmetric-difference #}

{#op||take||{{q1}} {{i}}||{{q2}}||
Returns a quotation {{q2}} containing the first _n_ values of the input quotation {{q1}}, or {{q1}} itself if {{i}} is greater than the length of {{q1}}. #}

{#op||tap||{{any}} {{q}}||{{any}}||
> Performs the following operations:
> 
> 1. Removes {{any}} from the stack.
> 2. For each quotation defined in {{q}} (which is a quotation of quotations each requiring one argument and returning one argument):
>    1. Pushes {{any}} back to the stack.
>    2. Dequotes the quotation and saves the result as {{any}}.
> 3. Push the resulting {{any}} back on the stack.
> 
> > %sidebar%
> > Example
> > 
> > The following program:
> > 
> >     {1 :a 2 :b 3 :c} (
> >       (stack.dup 'a dict.get succ succ 'a dict.set)
> >       (stack.dup 'b dict.get succ 'b dict.set)
> >     ) tap
> > 
> > Returns `{3 :a 3 :b 3 :c}`.#}

{#op||times||{{q}} {{i}}||{{a0p}}||
Applies the quotation {{q}} {{i}} times.#}

{#op||titleize||{{sl}}||{{s}}||
Returns a copy of {{sl}} in which the first character of each word is capitalized.#}

{#op||to-bin||{{i}}||{{s}}||
Converts {{i}} to its binary representation. #}

{#op||to-dec||{{i}}||{{s}}||
Converts {{i}} to its decimal representation. #}

{#op||to-hex||{{i}}||{{s}}||
Converts {{i}} to its hexadecimal representation. #}

{#op||to-json||{{any}}||{{s}}||
Converts {{any}} into a JSON string.#}

{#op||to-oct||{{i}}||{{s}}||
Converts {{i}} to its octal representation. #}

{#op||to-semver||{{d}}||{{s}}||
Given a a dictionary {{d}} containing a **major**, **minor**, and **patch** key/value pairs , it pushes a basic [SemVer](https://semver.org)-compliant string (with no additional labels) {{s}} on the stack.#}

{#op||to-yaml||{{any}}||{{s}}||
> Converts {{any}} into a YAML string.
>
> > %note%
> > Note
> > 
> > At present, only {{m}} dictionaries containing string values are supported.#}

{#op||tokenize||{{s}}||{{q}}||
Parses the min program {{s}} and returns a quotation {{q}} containing dictionaries with a `type` symbol and a `value` symbol for each token.#}

{#op||try||({{q1}} {{q}}{{2}}{{01}} {{q}}{{3}}{{01}})||{{a0p}}||
> Evaluates a quotation as a try/catch/finally block. 
> 
> The must contain the following elements:
> 
> 1. A quotation {{q1}} containing the code to be evaluated (_try_ block).
> 1. _(optional)_ A quotation {{q2}} containing the code to execute in case of error (_catch_ block).
> 1. _(optional)_ A quotation {{q3}} containing the code to execute after the code has been evaluated, whether an error occurred or not (_finally_ block).
> 
> > %sidebar%
> > Example
> > 
> > The following program executed on an empty stack prints the message "Insufficient items on the stack" and pushes 0 on the stack:
> > 
> >       (
> >         (stack.pop)
> >         (format-error puts)
> >         (0)
> >       ) try #}

{#op||type||{{any}}||{{s}}||
Returns the data type of {{any}}. In cased of typed dictionaries, the type name is prefixed by `dict:`, e.g. `dict:module`, `dict:socket`, etc.#}

{#op||type?||{{any}} {{sl}}||{{b}}||
Returns {{t}} if the data type of {{any}} satisfies the specified type expression {{sl}}, {{f}} otherwise. #}

{#op||typealias||{{sl1}} {{sl2}}||{{none}}||
Creates a type alias {{sl1}} for type expression {{sl2}}.#}

{#op||union||{{q1}} {{q2}}||{{q3}}||
> Calculates the union {{q3}} of {{q1}} and {{q2}}.
>
> > %sidebar%
> > Example
> > 
> > The following program leaves `(true 1 "test" "a" 2)` on the stack:
> > 
> >     (1 2 "test") ("test" "a" true 1) seq.union #}

{#op||unless||{{q1}} {{q2}}||{{a0p}}||
If {{1}} evaluates to {{f}} then evaluates {{2}}.#}

{#op||unseal-sigil||{{sl}}||{{none}}||
Unseals sigil {{sl}}, so that it can be re-defined (system sigils cannot be unsealed). #}

{#op||unseal-symbol||{{sl}}||{{none}}||
Unseals the user-defined symbol {{sl}}, so that it can be re-assigned. #}

{#op||uppercase||{{sl1}}||{{sl2}}||
Returns a copy of {{sl}} converted to uppercase.#}

{#op||version||{{none}}||{{s}}||
Returns the current min version number. #}

{#op||when||{{q1}} {{q2}}||{{a0p}}||
If {{q1}} evaluates to {{t}} then evaluates {{q2}}.#}

{#op||while||{{q1}} {{q2}}||{{a0p}}||
> Executes {{q2}} while {{q1}} evaluates to {{t}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program prints all natural numbers from 0 to 10:
> > 
> >     0 :count 
> >     (count 10 <=) 
> >     (count puts succ @count) while #}

{#op||with||{{q1}} {{q2}}||{{a0p}}||
Pushes each item of {{q1}} on the stack using the scope of {{q2}} as scope. #}

{#op||xor||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} and {{b2}} are different, {{f}} otherwise.#}

{#alias||&vert;&vert;||expect-any#}

{#sig||~||lambda-bind#}

{#alias||~||lambda-bind#}
