{@ _defs_.md || 0 @}

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

{#op||concat||(2) (1)||(\*)||
Concatenates {{2}} with {{1}}. #}

{#op||ddel||(D) §||(D')||
Returns a copy of {{d}} without the element with key {{sl}}. #}

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

{#op||first||(\*)||\*||
Returns the first element of {{q}}. #}

{#op||in?||(\*) \*||B||
Returns {{t}} if {{any}} is contained in {{q}}.#}

{#op||keys||(D)||(S+)||
Returns a quotation containing all the keys of dictionary {{d}}. #}

{#op||map||(2) (1)||(\*)||
Returns a new quotation {{q}} obtained by applying {{1}} to each element of {{2}}.#}

{#op||prepend||\* (\*)||(\*)||
Returns a new quotation containing the contents of {{q}} with [\*](class:kwd) prepended. #}

{#op||rest||(\*)||(\*)||
Returns a new quotation containing all elements of the input quotation except for the first. #}

{#op||reverse||(1)||(\*)||
Returns a new quotation {{q}} containing all elements of {{1}} in reverse order. #}

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

{#op||values||(D)||(\*+)||
Returns a quotation containing all the values of dictionary {{d}}. #}

