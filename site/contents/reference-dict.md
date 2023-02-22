-----
content-type: "page"
title: "dict Module"
-----
{@ _defs_.md || 0 @}

{#sig||/||dget#}

{#sig||%||dset#}

{#op||ddup||{{d1}}||{{d2}}||
Returns a copy of {{d1}}. #}

{#op||ddel||{{d}} {{sl}}||{{d}}||
Removes {{sl}} from {{d1}} and returns {{d1}}. #}

{#op||dget||{{d}} {{sl}}||{{any}}||
Returns the value of key {{sl}} from dictionary {{d}}. #}

{#op||dget-raw||{{d}} {{sl}}||{{rawval}}||
Returns the value of key {{sl}} from dictionary {{d}}, wrapped in a {{rawval}}. #}

{#op||dhas?||{{d}} {{sl}}||{{b}}||
> Returns {{t}} if dictionary {{d}} contains the key {{sl}}, {{f}} otherwise.
> 
> > %sidebar%
> > Example
> >  
> > The following program returns {{t}}:
> > 
> >     {true :a1 "aaa" :a2 false :a3} 'a2 dhas?
 #}

{#op||dkeys||{{d}}||({{s}}{{0p}})||
Returns a quotation containing all the keys of dictionary {{d}}. #}

{#op||dpick||{{d1}} {{q}}||{{d2}}||
> Returns a new dictionary {{d2}} containing the elements of {{d1}} whose keys are included in {{q}}.
> 
> > %sidebar%
> > Example
> >  
> > The following program returns `{4 :a 7 :d}`:
> > 
> >     {5 :q 4 :a 6 :c 7 :d "d" :a} ("a" "d") dpick
 #}

{#op||dpairs||{{d}}||({{a0p}})||
Returns a quotation containing all the keys (odd items) and values (even items) of dictionary {{d}}. #}

{#op||dset||{{d}} {{any}} {{sl}}||{{d}}||
Sets the value of the {{sl}} of {{d1}}  to {{any}}, and returns the modified dictionary {{d}}. #}

{#op||dset-sym||{{d}} {{sl}} {{sl}}||{{d}}||
Sets the value of the {{sl}} of {{d1}}  to {{sl}} (treating it as a symbol), and returns the modified dictionary {{d}}. #}

{#op||dtype||{{d}}||{{s}}||
Returns a string set to the type of {{d}} (empty if the dictionary has no type). #}

{#op||dvalues||{{d}}||({{a0p}})||
Returns a quotation containing all the values of dictionary {{d}}. #}
