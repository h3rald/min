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

{#op||all?||(2) (1)||B||
Applies predicate {{1}} to each element of {{2}} and returns {{t}} if all elements of {{2}} satisfy predicate {{1}}. #}

{#op||any?||(2) (1)||B||
Applies predicate {{1}} to each element of {{2}} and returns {{t}} if at least one element of {{2}} satisfies predicate {{1}}. #}

{#op||append||\* (1)||(\*)||
Returns a new quotation containing the contents of {{1}} with {{any}} appended. #}

{#op||apply||(1)||(\*)||
Returns a new quotation {{q}} obtained by evaluating each element of {{1}} in a separate stack.#}

{#op||at||(\*) I||\*||
Returns the {{i}}^th element of {{q}}.#}

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

{#op||concat||(2) (1)||(\*)||
Concatenates {{2}} with {{1}}. #}

{#op||ddel||(D) §||(D')||
Returns a copy of {{d}} without the element with key {{sl}}. #}

{#op||debug||{{null}}||{{null}}||
Toggles debug mode. #}

{#op||debug?||{{null}}||B||
Returns {{t}} if debug mode is on, {{f}} otherwise. #}

{#op||define||\* §||{{null}}||
Defines a new symbol {{sl}}, containing the specified value (auto-quoted).#}

{#op||delete||§||{{null}}||
Deletes the specified symbol {{sl}}.#}

{#op||dget||(D) §||\*||
Returns the value of key {{sl}}. #}

{#op||dhas?||(D) §||B||
> Returns {{t}} if dictionary {{d}} contains the key {{sl}}.
> 
> > %sidebar%
> > Example
> >  
> > The following program returns {{t}}:
> > 
> >     ((a1 true) (a2 "aaa") (a3 false)) 'a2 dhas?
 #}

{#op||dset||(D) \* §||(D')||
Sets the values of the {{sl}} of {{d}}  to {{any}}, and return a modified copy of {{d}}. #}

{#op||eval||S||\*?||
Parses and interprets {{s}}. #}

{#op||exit||{{null}}||{{null}}||
Exits the program or shell. #}

{#op||filter||(2) (1)||(\*)||
> Returns a new quotation {{q}} containing all elements of {{2}} that satisfy predicate {{1}}.
> 
> > %sidebar%
> > Example
> > 
> > The following program returns [(2 6 8 12)](class:kwd):
> > 
> >     (1 37 34 2 6 8 12 21) 
> >     (dup 20 < swap even? and) filter #}

{#op||first||(\*)||\*||
Returns the first element of {{q}}. #}

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

{#op||in?||(\*) \*||B||
Returns {{t}} if {{any}} is contained in {{q}}.#}

{#op||keys||(D)||(S+)||
Returns a quotation containing all the keys of dictionary {{d}}. #}

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

{#op||map||(2) (1)||(\*)||
Returns a new quotation {{q}} obtained by applying {{1}} to each element of {{2}}.#}

{#op||module||(\*) §||{{null}}||
Creates a new module {{sl}} based on quotation {{q}}. #}

{#op||module-sigils||(\*)||(S+)||
Returns a list of all sigils defined in module {{q}}.#}

{#op||module-symbols||(\*)||(S+)||
Returns a list of all symbols defined in module {{q}}.#}

{#op||prepend||\* (\*)||(\*)||
Returns a new quotation containing the contents of {{q}} with [\*](class:kwd) prepended. #}

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

{#op||rest||(\*)||(\*)||
Returns a new quotation containing all elements of the input quotation except for the first. #}

{#op||reverse||(1)||(\*)||
Returns a new quotation {{q}} containing all elements of {{1}} in reverse order. #}

{#op||save-symbol||§||{{null}}||
Saves the contents of symbol {{sl}} to the [.min\_symbols](class:file) file. #}

{#op||seal||§||{{null}}||
Seals symbol {{sl}}, so that it cannot be re-assigned. #}

{#op||sigils||{{null}}||(S+)||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||size||(\*)||I||
Returns the length of {{q}}.#}

{#op||sort||(2) (1)||(\*)||
> Sorts all elements of {{2}} according to predicate {{1}}. 
> 
> > %sidebar%
> > Example
> > 
> > The following programs returns [(1 3 5 7 9 13 16)](class:kwd):
> > 
> >     (1 9 5 13 16 3 7) '> sort #}

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

{#op||values||(D)||(\*+)||
Returns a quotation containing all the values of dictionary {{d}}. #}

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

