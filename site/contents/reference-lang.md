-----
content-type: "page"
title: "lang Module"
-----
{@ _defs_.md || 0 @}

{#sig||&apos;||quote#}

{#alias||&apos;||quote#}

{#sig||:||define#}

{#alias||:||define#}

{#alias||::||operator#}

{#sig||~||delete#}

{#sig||+||module#}

{#sig||^||call#}

{#alias||^||call#}

{#sig||?||help#}

{#alias||?||help#}

{#sig||&ast;||invoke#}

{#sig||@||bind#}

{#alias||@||bind#}

{#sig||&gt;||save-symbol#}

{#sig||&lt;||load-symbol#}

{#alias||->||dequote#}

{#alias||&gt;&gt;||prefix-dequote#}

{#alias||&gt;&lt;||infix-dequote#}

{#alias||=&gt;||apply#}

{#op||==&gt;||{{none}}||{{none}}||
Symbol used to separate input and output values in operator signatures.#}

{#alias||=-=||expect-empty-stack#}

{#sig||#||quote-bind#}

{#alias||#||quote-bind#}

{#sig||=||quote-define#}

{#alias||=||quote-define#}

{#op||apply||{{q}}||({{a0p}})||
Returns a new quotation obtained by evaluating each element of {{q}} in a separate stack. #}

{#op||args||{{none}}||{{q}}||
Returns a list of all arguments passed to the current program.#}

{#op||bind||{{any}} {{sl}}||{{none}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

{#op||bool||{{any}}||{{b}}||
> Converts {{any}} to a boolean value based on the following rules:
> 
>  * If {{any}} is a boolean value, no conversion is performed.
>  * If {{any}} is {{null}}, it is converted to {{f}}.
>  * If {{any}} is a numeric value, zero is converted to {{f}}, otherwise it is converted to {{t}}.
>  * If {{any}} is a quotation or a dictionary, the empty quotation or dictionary is converted to {{f}}, otherwise it is converted to {{t}}.
>  * If {{any}} is a string, the empty string, and `"false"` are converted to {{f}}, otherwise it is converted to {{t}}.#}

{#op||call||{{d}} {{sl}}||{{a0p}}||
Calls operator {{sl}} defined in dictionary {{d}}. #}

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
> >     2 (
> >        ((> 3) ("Greater than 3" put!))
> >        ((< 3) ("Smaller than 3" put!))
> >        ((true) ("Exactly 3" put!))
> >     ) case #}

{#op||compiled?||{{none}}||{{b}}||
Returns {{t}} if the current program has been compiled.#}

{#op||define||{{any}} {{sl}}||{{none}}||
Defines a new symbol {{sl}}, containing the specified value (auto-quoted if not already a quotation).#}

{#op||define-sigil||{{any}} {{sl}}||{{none}}||
Defines a new sigil {{sl}}, containing the specified value (auto-quoted if not already a quotation).#}

{#op||defined?||{{sl}}||{{b}}||
Returns {{t}} if the symbol {{sl}} is defined, {{f}} otherwise.#}

{#op||defined-sigil?||{{sl}}||{{b}}||
Returns {{t}} if the symbol {{sl}} is defined, {{f}} otherwise.#}

{#op||delete||{{sl}}||{{none}}||
Deletes the specified symbol {{sl}}.#}

{#op||delete-sigil||{{sl}}||{{none}}||
Deletes the specified user-defined sigil {{sl}}.#}

{#op||dequote||{{q}}||{{a0p}}||
> Pushes the contents of quotation {{q}} on the stack.
>
> Each element is pushed on the stack one by one. If any error occurs, {{q}} is restored on the stack.#}

{#op||eval||{{s}}||{{a0p}}||
Parses and interprets {{s}}. #}

{#op||exit||{{i}}||{{none}}||
Exits the program or shell with {{i}} as return code. #}

{#op||expect||{{q1}}||{{q2}}||
> Validates the first _n_ elements of the stack against the type descriptions specified in {{q1}} (_n_ is {{q1}}'s length) and if all the elements are valid returns them wrapped in {{q2}} (in reverse order). 

> > %tip%
> > Tips
> > 
> > * You can specify a typed dictionary by prepending the type name with `dict:`. Example: `dict:socket`
> > * You can specify two or more matching types by separating the type names with a pipe: `string|quot`

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

{#op||expect-empty-stack||{{none}}||{{none}}||
Raises an error if the stack is not empty.#}

{#op||float||{{any}}||{{flt}}||
> Converts {{any}} to an integer value based on the following rules:
> 
>   * If {{any}} is {{t}}, it is converted to `1.0`.
>   * If {{any}} is {{f}}, it is converted to `0.0`.
>   * If {{any}} is {{null}}, it is converted to `0.0`
>.  * If {{any}} is a integer, it is converted to float value.
>   * If {{any}} is a float, no conversion is performed.
>   * If {{any}} is a string, it is parsed as a float value.#}

{#op||foreach||{{q1}} {{q2}}||{{a0p}}||
Applies the quotation {{q2}} to each element of {{q1}}.#}

{#op||format-error||{{e}}||{{s}}||
> Formats the error {{e}} as a string. 
> > %sidebar%
> > Example
> > 
> > The following: 
> > 
> > `{"MyError" :error "This is a test error" :message} 'error set-type format-error`
> > 
> > produces: `"This is a test error"`#}

{#op||from-json||{{s}}||{{any}}||
Converts a JSON string into {{m}} data.#}

{#op||from-yaml||{{s}}||{{any}}||
> Converts a YAML string into {{m}} data.
> > %note%
> > Note
> > 
> > At present, only YAML objects containing string values are supported.#}

{#op||gets||{{none}}||{{s}}||
Reads a line from STDIN and places it on top of the stack as a string.#}

{#op||help||{{sl}}||{{none}}||
Prints the help text for {{sl}}, if available. #}

{#op||if||{{q1}} {{q2}} {{q3}}||{{a0p}}||
If {{q1}} evaluates to {{t}} then evaluates {{q2}}, otherwise evaluates {{q3}}.#}

{#op||import||{{sl}}||{{none}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

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

{#op||int||{{any}}||{{i}}||
> Converts {{any}} to an integer value based on the following rules:
> 
>   * If {{any}} is {{t}}, it is converted to `1`.
>   * If {{any}} is {{f}}, it is converted to `0`.
>   * If {{any}} is {{null}}, it is converted to `0`.
>   * If {{any}} is an integer, no conversion is performed.
>   * If {{any}} is a float, it is converted to an integer value by truncating its decimal part.
>   * If {{any}} is a string, it is parsed as an integer value.#}

{#op||invoke||{{sl}}||{{a0p}}||
> Assming that {{sl}} is a formatted like *dictionary*/*symbol*, calls *symbol* defined in *dictionary* (note that this also works for nested dictionaries. 
> 
> > %sidebar%
> > Example
> > 
> > The following program leaves `100` on the stack:
> > 
> >     {{100 :b} :a} :test *test/a/b
 #}

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
> >    5 (dup 0 ==) 'succ (dup pred) '* linrec
 #}

{#op||lite?||{{none}}||{{b}}||
Returns {{t}} if min was built in _lite_ mode. #}

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
Returns the current log level (debug, info, notive, warn, error or fatal). #}

{#op||module||{{d}} {{sl}}||{{none}}||
Creates a new module {{sl}} based on dictionary {{d}}. #}

{#op||operator||{{q}}||{{a0p}}||
> Provides a way to define a new operator (symbol or sigil) on the current scope performing additional checks (compared to `define` and `define-sigil`), and automatically mapping inputs and outputs.
> 
> {{q}} is a quotation containing:
> 
> * A symbol identifying the type of operator to define (`symbol` or `sigil`).
> * A symbol identifying the name of the operator.
> * A quotation defining the signature of the operatorm containing input and output values identified by their type and a capturing symbol, separated by the `==>` symbol.
> * A quotation identifying the body of the operator.
>
> The main additional features offered by this way of defining operators are the following:
>
> * Both input and output values are checked against a type (like when using the `expect` operator *and* automatically captured in a symbol that can be referenced in the operator body quotation.
> * The full signature of the operator is declared, making the resulting code easier to understand at quick glance.
> * An exception is automatically raised if the operator body pollutes the stack by adding or removing elementa from the stack (besides adding the declared output values).
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

{#op||parse||{{s}}||{{q}}||
Parses {{s}} and returns a quoted program {{q}}. #}

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

{#op||prompt||{{none}}||{{s}}||
> This symbol is used to configure the prompt of the min shell. By default, it is set to the following quotation:
> 
>     ("[$1]$$ " (.) => %)
> 
> Unlike other predefined symbols, this symbol is _unsealed_, which means it can be modified.#}

{#op||publish||{{sl}} {{d}}||{{none}}||
> Publishes symbol {{sl}} to the scope of {{d}}.
> 
> > %sidebar%
> > Example
> > 
> Publish symbol [my-local-symbol](class:kwd) to [ROOT](class:kwd) scope:
> > `'my-local-symbol ROOT publish` #}

{#op||puts||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT.#}

{#op||quit||{{none}}||{{none}}||
Exits the program or shell with 0 as return code. #}

{#op||quote||{{any}}||({{any}})||
Wraps {{any}} in a quotation. #}

{#op||quote-bind||{{any}} {{sl}}||{{none}}||
Quotes {{any}} and binds the quotation to the existing symbol {{sl}}. #}

{#op||quote-define||{{any}} {{sl}}||{{none}}||
Quotes {{any}} and assigns the quotation to the symbol {{sl}}, creating it if not already defined. #}

{#op||raise||{{e}}||{{none}}||
Raises the error specified via the dictionary {{e}}.#}

{#op||raw-args||{{none}}||{{q}}||
Returns a list of all arguments and (non-parsed) options passed to the current program.#}

{#op||remove-symbol||{{sl}}||{{none}}||
Removes the symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||require||{{sl}}||{{d}}||
Parses and interprets (in a separater interpreter) the specified {{m}} file {{sl}}, adding [.min](class:ext) if not specified, and returns a module dictionary {{d}} containing all the symbols defined in {{sl}}. #}

{#op||return||{{none}}||{{none}}||
If used within the body quotation of an operator definition, causes the interpreter to stop pushing further body elements on the stack and start pushing tbe operator output values on the stack. 

If used outside of the body quotation of an operator definition, it raises an exception.#}

{#op||ROOT||{{none}}||{{d}}||
Returns a module holding a reference to the [ROOT](class:kwd) scope.

> > %tip%
> > Tip
> > 
> > This symbol is very useful in conjunction with the **with** operator.
 #}

{#op||save-symbol||{{sl}}||{{none}}||
Saves the contents of symbol {{sl}} to the [.min\_symbols](class:file) file. #}

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

{#op||saved-symbols||{{none}}||({{s0p}})||
Returns a quotation containing all symbols saved in the [.min\_symbols](class:file) file. #}

{#op||scope-sigils||{{d}}||({{s0p}})||
Returns a list of all sigils defined in dictionary {{d}}.#}

{#op||scope-symbols||{{d}}||({{s0p}})||
Returns a list of all symbols defined in dictionary {{d}}.#}

{#op||seal||{{sl}}||{{none}}||
Seals symbol {{sl}}, so that it cannot be re-assigned. #}

{#op||seal-sigil||{{sl}}||{{none}}||
Seals the user-defined sigil {{sl}}, so that it cannot be re-defined. #}

{#op||sealed?||{{sl}}||{{b}}||
Returns {{t}} if the symbol {{sl}} is sealed, {{f}} otherwise.#}

{#op||sealed-sigil?||{{sl}}||{{b}}||
Returns {{t}} if the sigil {{sl}} is sealed, {{f}} otherwise.#}

{#op||set-type||{{d}} {{sl}}||{{d}}||
Sets the type for dictionary {{d}} to {{sl}}.#}

{#op||sigil-help||{{sl}}||{{help}}|{{null}}||
Returns the help dictionary for the sigil {{sl}}, if available, {{null}} otherwise. #}

{#op||sigils||{{none}}||({{s0p}})||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||source||{{sl}}||{{q}}||
Display the source code of symbol {{sl}} (if it has been implemented a {{m}} quotation). #}

{#op||string||{{any}}||{{s}}||
Converts {{any}} to its string representation.#}

{#op||symbols||{{none}}||({{s0p}})||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

{#op||symbol-help||{{sl}}||{{help}}|{{null}}||
Returns the help dictionary for the symbol {{sl}}, if available, {{null}} otherwise. #}

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
> >       (dup /a  succ succ %a)
> >       (dup /b  succ %b)
> >     ) tap
> > 
> > Returns `{3 :a 3 :b 3 :c}`.#}

{#op||times||{{q}} {{i}}||{{a0p}}||
Applies the quotation {{q}} {{i}} times.#}

{#op||to-json||{{any}}||{{s}}||
Converts {{any}} into a JSON string.#}

{#op||to-yaml||{{any}}||{{s}}||
> Converts {{any}} into a YAML string.
>
> > %note%
> > Note
> > 
> > At present, only {{m}} dictionaries containing string values are supported.#}

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
> >         (pop)
> >         (format-error puts)
> >         (0)
> >       ) try #}

{#op||typeclass||{{q}} {{sl}}||{{none}}||
> Defines a new type class {{sl}} set to quotation {{q}}, which can be used in operator signatures.
> 
> > %sidebar%
> > Example
> > 
> > Consider the following type class which defines a natural number: 
> >
> >      (:n ((n integer?) (n 0 >)) &&) 'natural typeclass
> > 
> > It can now be used in operator signatures, like this:
> > 
> >      (
> >        symbol natural-sum
> >        (natural :n natural :m ==> natural :result)
> >        (n m + @result)
> >      ) :: #}

{#op||unless||{{q1}} {{q2}}||{{a0p}}||
If {{1}} evaluates to {{f}} then evaluates {{2}}.#}

{#op||unseal||{{sl}}||{{none}}||
Unseals the user-defined symbol {{sl}}, so that it can be re-assigned. #}

{#op||unseal-sigil||{{sl}}||{{none}}||
Unseals sigil {{sl}}, so that it can be re-defined (system sigils cannot be unsealed). #}

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
Pushes each item of {{q1}} on the stack using the scope of {{q2}} as scope. 

> > %sidebar%
> > Example
> > 
> > This operator is useful to define symbols on the [ROOT](class:kwd) scope or another scope. For example min's prelude includes the following code used to import certain modules only if min was not compiled in lite mode:
> > 
> >     'lite? (
> >      (
> >       'crypto    import
> >       'math      import
> >       'net       import
> >       'http      import
> >      ) ROOT with
> >     ) unless
 #}
