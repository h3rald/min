{@ _defs_.md || 0 @}

{#sig||&apos;||quote#}

{#alias||&apos;||quote#}

{#sig||:||define#}

{#alias||:||define#}

{#sig||~||delete#}

{#sig||+||module#}

{#sig||^||call#}

{#alias||^||call#}

{#sig||@||bind#}

{#alias||@||bind#}

{#sig||>||save-symbol#}

{#sig||<||load-symbol#}

{#alias||->||dequote#}

{#alias||=>||apply#}

{#sig||#||quote-define#}

{#sig||=||quote-bind#}

{#op||apply||{{q}}||({{a0p}})||
Returns a new quotation {{q}} obtained by evaluating each element of {{q}} in a separate stack.#}

{#op||args||{{null}}||{{q}}||
Returns a list of all arguments passed to the current program.#}

{#op||bind||{{any}} {{sl}}||{{null}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

{#op||bool||{{any}}||{{b}}||
> Converts {{any}} to a boolean value based on the following rules:
> 
>  * If {{any}} is a boolean value, no conversion is performed.
>  * If {{any}} is a non-zero numeric value, it is converted to {{t}}, otherwise it is converted to {{f}}.
>  * If {{any}} is a non-empty quotation, it is converted to {{t}}, otherwise it is converted to {{f}}.
>  * If {{any}} is a non-empty string or not `"false"`, it is converted to {{t}}, otherwise it is converted to {{f}}.#}

{#op||call||{{q}} {{sl}}||{{a0p}}||
Calls operator {{sl}} defined in scope {{q}}. #}

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

{#op||debug||{{null}}||{{null}}||
Toggles debug mode. #}

{#op||debug?||{{null}}||{{b}}||
Returns {{t}} if debug mode is on, {{f}} otherwise. #}

{#op||define||{{any}} {{sl}}||{{null}}||
Defines a new symbol {{sl}}, containing the specified value (auto-quoted if not already a quotation).#}

{#op||defined?||{{sl}}||{{b}}||
Returns {{t}} if {{sl}} is defined, {{f}} otherwise.#}

{#op||delete||{{sl}}||{{null}}||
Deletes the specified symbol {{sl}}.#}

{#op||dequote||{{q}}||{{a0p}}||
Pushes the contents of quotation {{q}} on the stack. #}

{#op||eval||{{s}}||{{a0p}}||
Parses and interprets {{s}}. #}

{#op||exit||{{i}}||{{null}}||
Exits the program or shell with {{i}} as return code. #}

{#op||expect||{{q1}}||{{q2}}||
> Validates the first _n_ elements of the stack against the type descriptions specified in {{q1}} (_n_ is {{q1}}'s length) and if all the elements are valid returns them wrapped in {{q2}} (in reverse order).
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

{#op||float||{{any}}||{{flt}}||
> Converts {{any}} to an integer value based on the following rules:
> 
>   * If {{any}} is {{t}}, it is converted to `1.0`.
>   * If {{any}} is {{f}}, it is converted to `0.0`.
>   * If {{any}} is a integer, it is converted to float value.
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
> > `((error "MyError") (message "This is a test error")) format-error`
> > 
> > produces: `"This is a test error"`#}

{#op||from-json||{{s}}||{{a0p}}||
Converts a JSON string into {{m}} data.#}

{#op||if||{{q1}} {{q2}} {{q3}}||{{a0p}}||
If {{q1}} evaluates to {{t}} then evaluates {{q2}}, otherwise evaluates {{q3}}.#}

{#op||import||{{sl}}||{{null}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

{#op||int||{{any}}||{{i}}||
> Converts {{any}} to an integer value based on the following rules:
> 
>   * If {{any}} is {{t}}, it is converted to `1`.
>   * If {{any}} is {{f}}, it is converted to `0`.
>   * If {{any}} is an integer, no conversion is performed.
>   * If {{any}} is a float, it is converted to an integer value by truncating its decimal part.
>   * If {{any}} is a string, it is parsed as an integer value.#}

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
> >     (dup 0 ==) 'succ (dup pred) '* linrec
 #}

{#op||load||{{sl}}||{{a0p}}||
Parses and interprets the specified {{m}} file, adding [.min](class:ext) if not specified. #}

{#op||load-symbol||{{sl}}||{{a0p}}||
Loads the contents of symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||loglevel||{{sl}}||{{null}}||
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

{#op||module||{{q}} {{sl}}||{{null}}||
Creates a new module {{sl}} based on quotation {{q}}. #}

{#op||module-sigils||{{q}}||({{s0p}})||
Returns a list of all sigils defined in module {{q}}.#}

{#op||module-symbols||{{q}}||({{s0p}})||
Returns a list of all symbols defined in module {{q}}.#}

{#op||opts||{{null}}||{{d}}||
Returns a dictionary of all options passed to the current program, with their respective values.#}

{#op||prompt||{{null}}||{{s}}||
> This symbol is used to configure the prompt of the min shell. By default, it is set to the following quotation:
> 
>     ([$1]$$ " (.) => %)
> 
> Unlike other predefined symbols, this symbol is _unsealed_, which means it can be modified.#}

{#op||publish||{{sl}} {{q}}||{{null}}||
> Publishes symbol {{sl}} to the scope of {{q}}.
> 
> > %sidebar%
> > Example
> > 
> Publish symbol [my-local-symbol](class:kwd) to [ROOT](class:kwd) scope:
> > `'my-local-symbol ROOT publish` #}

{#op||quote||{{any}}||({{any}})||
Wraps {{any}} in a quotation. #}

{#op||quote-bind||{{any}} {{sl}}||{{null}}||
Quotes {{any}} and binds the quotation to the existing symbol {{sl}}. #}

{#op||quote-define||{{any}} {{sl}}||{{null}}||
Quotes {{any}} and assigns the quotation to the symbol {{sl}}, creating it if not already defined. #}

{#op||raise||{{e}}||{{null}}||
Raises the error specified via the dictionary {{e}}.#}

{#op||remove-symbol||{{sl}}||{{null}}||
Removes the symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||save-symbol||{{sl}}||{{null}}||
Saves the contents of symbol {{sl}} to the [.min\_symbols](class:file) file. #}

{#op||seal||{{sl}}||{{null}}||
Seals symbol {{sl}}, so that it cannot be re-assigned. #}

{#op||sigils||{{null}}||({{s0p}})||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||source||{{sl}}||{{q}}||
Display the source code of symbol {{sl}} (if it has been implemented a {{m}} quotation). #}

{#op||stored-symbols||{{null}}||({{s0p}})||
Returns a quotation containing all symbols stored in the [.min\_symbols](class:file) file. #}

{#op||string||{{any}}||{{s}}||
Converts {{any}} to its string representation.#}

{#op||symbols||{{null}}||({{s0p}})||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

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
> >     (
> >       ((a 1) (b 2) (c 3)) (
> >       (dup /a  succ succ %a)
> >       (dup /b  succ %b)
> >     ) tap
> > 
> > Returns `((a 3) (b 3) (c 3))`.#}

{#op||tap!||{{any}} {{q}}||{{any}}||
> Performs the following operations:
> 
> 1. Removes {{any}} from the stack.
> 2. For each quotation defined in {{q}} (which is a quotation of quotations each requiring one argument and returning one argument):
>    1. Pushes {{any}} back to the stack.
>    2. Dequotes the quotation and saves the result as {{any}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program:
> > 
> >     "" :s1
> >     "test" (
> >       (' "1" swap append "" join)
> >       (' "2" swap append "" join)
> >       (' "3" swap append "" join @s1 s1)
> >     ) tap!
> > 
> > Sets `s1` to `"test123"`. #}

{#op||times||{{q}} {{i}}||{{a0p}}||
Applies the quotation {{q}} {{i}} times.#}

{#op||to-json||{{q}}||{{s}}||
Converts {{q}} into a JSON string {{s}}.#}

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

{#op||unless||{{q1}} {{q2}}||{{a0p}}||
If {{1}} evaluates to {{f}} then evaluates {{2}}.#}

{#op||unseal||{{sl}}||{{null}}||
Unseals symbol {{sl}}, so that it can be re-assigned. #}

{#op||version||{{null}}||{{s}}||
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
Applies quotation {{q1}} within the scope of {{q2}}. #}
