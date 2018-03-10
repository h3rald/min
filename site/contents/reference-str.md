-----
content-type: "page"
title: "str Module"
-----
{@ _defs_.md || 0 @}

{#alias||%||interpolate#}

{#alias||=~||regex#}

{#op||capitalize||{{sl}}||{{s}}||
Returns a copy of {{sl}} with the first character capitalized.#}

{#op||indent||{{sl}} {{i}}||{{s}}||
Returns {{s}} containing {{sl}} indented with {{i}} spaces.#}

{#op||indexof||{{s1}} {{s2}}||{{i}}||
If {{s2}} is contained in {{s1}}, returns the index of the first match or -1 if no match is found. #}

{#op||interpolate||{{s}} {{q}}||{{s}}||
> Substitutes the placeholders included in {{s}} with the values in {{q}}.
> > %note%
> > Note
> > 
> > If {{q}} contains symbols or quotations, they are not interpreted. To do so, call `apply` before interpolating. 
> 
> > %sidebar%
> > Example
> >  
> > The following code (executed in a directory called '/Users/h3rald/Development/min' containing 19 files):
> > 
> > `"Directory '$1' includes $2 files." (. (. ls 'file? filter size)) apply interpolate`
> > 
> > produces:
> > 
> > `"Directory '/Users/h3rald/Development/min' includes 19 files."`#}

{#op||join||{{q}} {{sl}}||{{s}}||
Joins the elements of {{q}} using separator {{sl}}, producing {{s}}.#}

{#op||length||{{sl}}||{{i}}||
Returns the length of {{sl}}.#}

{#op||lowercase||{{sl}}||{{s}}||
Returns a copy of {{sl}} converted to lowercase.#}

{#op||match||{{s1}} {{s2}}||{{b}}||
> Returns {{t}} if {{s2}} matches {{s1}}, {{f}} otherwise.
> > %tip%
> > Tip
> > 
> > {{s2}} can be a {{sgregex}}-compatible regular expression.#}

{#op||repeat||{{sl}} {{i}}||{{s}}||
Returns {{s}} containing {{sl}} repeated {{i}} times.#}

{#op||replace||{{s1}} {{s2}} {{s3}}||{{s4}}||
> Returns a copy of {{s1}} containing all occurrences of {{s2}} replaced by {{s3}}
> > %tip%
> > Tip
> > 
> > {{s2}} can be a {{sgregex}}-compatible regular expression.
> 
> > %sidebar%
> > Example
> > 
> > The following:
> > 
> > `"This is a stupid test. Is it really a stupid test?" " s[a-z]+" " simple" replace`
> > 
> > produces: `"This is a simple test. Is it really a simple test?"`#}

{#op||regex||{{s1}} {{s2}}||{{q}}||
> Performs a search and/or a search-and-replace operation using pattern {{s2}}.
> 
> {{s2}} can be one of the following patterns:
> 
>   * **/**_search-regex_**/**_modifiers_
>   * **s/**_search-regex_**/**_replacemenet_**/**_modifiers_
> 
> {{q}} is always a quotation containing:
> 
>   * One or more strings containing the first match and captures (if any), like for the `search` operator.
>   * A string containing the resuling string after the search-and-replace operation.
> 
> > %tip%
> > Tip
> > 
> > * _search-regex_ can be a {{sgregex}}-compatible regular expression.
> > * _modifiers_ are optionals can contain one or more of the following characters, in any order:
> >   * **i**: case-insensitive match.
> >   * **m**: multi-line match.
> >   * **s**: dot character includes newlines.
> 
> > %sidebar%
> > Example: Search
> > 
> > The following:
> > 
> > `"This is a GOOD idea." "/(good) idea/i" regex`
> > 
> > produces: `("GOOD idea", "GOOD")`
> 
> > %sidebar%
> > Example: Search and Replace
> > 
> > The following:
> > 
> > `"This is a GOOD idea." "s/good/bad/i" regex`
> > 
> > produces: `("This is a bad idea")`#}

{#op||search||{{s1}} {{s2}}||{{q}}||
> Returns a quotation containing the first occurrence of {{s2}} within {{s2}}. Note that:
> 
>   * The first element of {{q}} is the matching substring.
>   * Other elements (if any) contain captured substrings.
> 
> > %tip%
> > Tip
> > 
> > {{s2}} can be a {{sgregex}}-compatible regular expression.
> 
> > %sidebar%
> > Example
> > 
> > The following:
> > 
> > `"192.168.1.1, 127.0.0.1" "[0-9]+\.[0-9]+\.([0-9]+)\.([0-9]+)" search`
> > 
> > produces: `("192.168.1.1", "1", "1")`#}

{#op||split||{{sl1}} {{sl2}}||{{q}}||
Splits {{sl1}} using separator {{sl2}} and returns the resulting strings within the quotation {{q}}. #}

{#op||strip||{{sl}}||{{s}}||
Returns {{s}}, which is set to {{sl}} with leading and trailing spaces removed.#} 

{#op||substr||{{s1}} {{i1}} {{i2}}||{{s2}}||
Returns a substring {{s2}} obtained by retriving {{i2}} characters starting from index {{i1}} within {{s1}}.#}

{#op||titleize||{{sl}}||{{s}}||
Returns a copy of {{sl}} in which the first character of each word is capitalized.#}

{#op||uppercase||{{sl1}}||{{sl2}}||
Returns a copy of {{sl}} converted to uppercase.#}

