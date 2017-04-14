{@ _defs_.md || 0 @}

{#sig||'||quote#}

{#alias||'||quote#}

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

{#op||bind||\* §||{{null}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

{#op||call||(\*) §||\*?||
Calls operator {{sl}} defined in scope {{q}}. #}

{#op||case||(1)||\*?||
> {{1}} is a quotation containing _n_ different conditional branches. 
> 
> Each branch must be a quotation containing two quotations, and it is processed as follows:
> 
>   * if the first quotation evaluates to {{t}}, then the second quotation is executed.
>   * if the first quotation evaluates to {{f}}, then the following branch is processed (if any).
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

{#op||foreach||(2) (1)||\*?||
Applies the quotation {{1}} to each element of {{2}}.#}

{#op||format-error||(E)||S||
Formats the error {{e}} as a string.

> %sidebar%
> Example
> 
> The following: 
> 
> `((error "MyError") (message "This is a test error")) format-error`
> 
> produces: `"This is a test error"`#}

{#op||from-json||S||\*||
Converts a JSON string into {{M -> min}} data.#}

{#op||if||(3) (2) (1)||\*?||
If {{3}} evaluates to {{t}} then evaluates {{2}}, otherwise evaluates {{1}}.#}

{#op||import||§||{{null}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

{#op||linrec||(4) (3) (2) (1)||\*?||
> Implements linear recursions as follows:
> 
>   1. Evaluates {{4}}.
>     * If {{4}} evaluates to {{t}}, then it evaluates {{3}}.
>     * Otherwises it executes {{2}} and recurses using the same four quotations.
>   2. Finally, it executes {{1}}.
> 
> > %sidebar%
> > Example
> > 
> > The following programs returns [120](class:kwd), the factorial of 5:
> > 
> >     (dup 0 ==) 'succ (dup pred) '* linrec
 #}

{#op||load||S||\*?||
Parses and interprets the specified {{M}} file {{s}}, adding [.min](class:ext) if not specified. #}

{#op||load-symbol||§||\*||
Loads the contents of symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||loglevel||§||{{null}}||
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

{#op||module||(\*) §||{{null}}||
Creates a new module {{sl}} based on quotation {{q}}. #}

{#op||module-sigils||(\*)||(S+)||
Returns a list of all sigils defined in module {{q}}.#}

{#op||module-symbols||(\*)||(S+)||
Returns a list of all symbols defined in module {{q}}.#}

{#op||publish||§ (*)||{{null}}||
Publishes symbol {{sl}} to the scope of [(\*)](class:kwd).
> 
> > %sidebar%
> > Example
> > 
> Publish symbol [my-local-symbol](class:kwd) to [ROOT](class:kwd) scope:
> > `'my-local-symbol ROOT publish` #}

{#op||quote||\*||(\*)||
Wraps [\*](class:kwd) in a quotation. #}

{#op||quote-bind||\* §||{{null}}||
Quotes {{any}} and binds the quotation to the existing symbol {{sl}}. #}

{#op||quote-define||\* §||{{null}}||
Quotes {{any}} and assigns the quotation to the symbol {{sl}}, creating it if not already defined. #}

{#op||raise||(E)||{{null}}||
Raises the error specified via the dictionary {{e}}.#}

{#op||remove-symbol||§||{{null}}||
Removes the symbol {{sl}} from the [.min\_symbols](class:file) file. #}

{#op||save-symbol||§||{{null}}||
Saves the contents of symbol {{sl}} to the [.min\_symbols](class:file) file. #}

{#op||seal||§||{{null}}||
Seals symbol {{sl}}, so that it cannot be re-assigned. #}

{#op||sigils||{{null}}||(S+)||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||source||§||(\*)||
Display the source code of symbol {{sl}} (if it has been implemented a {{M}} quotation). #}

{#op||stored-symbols||{{null}}||(S+)||
Returns a quotation containing all symbols stored in the [.min\_symbols](class:file) file. #}

{#op||symbols||{{null}}||(S+)||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

{#op||times||(\*) I||\*?||
Applies the quotation {{q}} {{i}} times.#}

{#op||to-json||(\*)||S||
Converts a quotation into a JSON string {{s}}.#}

{#op||try||(\*)||\*?||
Evaluates quotation {{q}} as a try/catch/finally block. 
> 
> {{q}} must contain the following elements:
> 
> 1. A quotation containing the code to be evaluated (_try_ block).
> 1. _(optional)_ A quotation containing the code to execute in case of error (_catch_ block).
> 1. _(optional)_ A quotation containing the code to execute after the code has been evaluated, whether an error occurred or not (_finally_ block).
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

{#op||unless||(2) (1)||\*?||
If {{2}} evaluates to {{f}} then evaluates {{1}}.#}

{#op||unquote||(\*)||\*||
Pushes the contents of quotation {{q}} on the stack. #}

{#op||unseal||§||{{null}}||
Unseals symbol {{sl}}, so that it can be re-assigned. #}

{#op||version||{{null}}||S||
Returns the current min version number. #}

{#op||when||(2) (1)||\*?||
If {{2}} evaluates to {{t}} then evaluates {{1}}.#}

{#op||while||(2) (1)||\*?||
> Executes {{1}} while {{2}} evaluates to {{t}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program prints all natural numbers from 0 to 10:
> > 
> >     0 :count 
> >     (count 10 <=) 
> >     (count puts succ @count) while #}

{#op||with||(2) (1)||\*?||
Applies quotation {{2}} within the scope of {{1}}. #}

