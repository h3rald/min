{@ _defs_.md || 0 @}

{#sig||&apos;||quote#}

{#alias||&apos;||quote#}

{#sig||:||define#}

{#alias||:||define#}

{#sig||~||delete#}

{#sig||+||module#}

{#sig||^||call#}

{#alias||^||call#}

{#sig||/||dget#}

{#sig||@||bind#}

{#alias||@||bind#}

{#sig||%||dset#}

{#sig||>||save-symbol#}

{#sig||<||load-symbol#}

{#alias||->||unquote#}

{#alias||=>||apply#}

{#sig||#||quote-define#}

{#sig||=||quote-bind#}

{#op||bind||{{any}} {{sl}}||{{null}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

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

{#op||delete||{{sl}}||{{null}}||
Deletes the specified symbol {{sl}}.#}

{#op||eval||{{s}}||{{a0p}}||
Parses and interprets {{s}}. #}

{#op||exit||{{null}}||{{null}}||
Exits the program or shell. #}

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

{#op||symbols||{{null}}||({{s0p}})||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

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

{#op||unquote||{{q}}||{{a0p}}||
Pushes the contents of quotation {{q}} on the stack. #}

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
