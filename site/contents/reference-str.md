-----
content-type: "page"
title: "str Module"
-----
{@ _defs_.md || 0 @}

{#alias||%||interpolate#}

{#alias||=%||apply-interpolate#}

{#alias||=~||regex#}

{#op||apply-interpolate||{{s}} {{q}}||{{s}}||
The same as pushing `apply` and then `interpolate` on the stack.#}

{#op||capitalize||{{sl}}||{{s}}||
Returns a copy of {{sl}} with the first character capitalized.#}

{#op||chr||{{i}}||{{s}}||
Returns the single character {{s}} obtained by interpreting {{i}} as an ASCII code.#}

{#op||escape||{{sl}}||{{s}}||
Returns a copy of {{sl}} with quotes and backslashes escaped with a backslash.#}

{#op||from-semver||{{s}}||{{d}}||
Given a basic [SemVer](https://semver.org)-compliant string (with no additional labels) {{s}}, 
it pushes a dictionary {{d}} on the stack containing a **major**, **minor**, and **patch** key/value pairs.#}

{#op||indent||{{sl}} {{i}}||{{s}}||
Returns {{s}} containing {{sl}} indented with {{i}} spaces.#}

{#op||indexof||{{s1}} {{s2}}||{{i}}||
If {{s2}} is contained in {{s1}}, returns the index of the first match or -1 if no match is found. #}

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

{#op||match?||{{s1}} {{s2}}||{{b}}||
> Returns {{t}} if {{s2}} matches {{s1}}, {{f}} otherwise.
> > %tip%
> > Tip
> > 
> > {{s2}} is a {{pcre}}#}.

{#op||ord||{{s}}||{{i}}||
Returns the ASCII code {{i}} corresponding to the single character {{s}}.#}

{#op||parse-url||{{s}}||{{url}}||
Parses the url {{s}} into its components and stores them into {{url}}.#} 

{#op||prefix||{{sl1}} {{sl2}}||{{s}}||
Prepends {{sl2}} to {{sl1}}.#}

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
> Returns a copy of {{s1}} containing all occurrences of {{s2}} replaced by applying {{q}} to each quotation correponding to each match.
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
> > `":1::2::3::4:" ":(\d):" (=m m 1 get :d "-$#-" (d) =%) replace-apply`
> > 
> > produces:
> > 
> > `"-1--2--3--4-"`
> > 
> > Note that for each match the following quotations (each containing tbe full matcb and the captured matches) are produced as input for the replace quotation:
> >      ("-1-" "1")
> >      ("-2-" "2")
> >      ("-3-" "3")
> >      ("-4-" "4") #}

{#op||search||{{s1}} {{s2}}||{{q}}||
> Returns a quotation containing the first occurrence of {{s2}} within {{s1}}. Note that:
> 
>   * The first element of {{q}} is the matching substring.
>   * Other elements (if any) contain captured substrings.
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

{#op||split||{{sl1}} {{sl2}}||{{q}}||
Splits {{sl1}} using separator {{sl2}} (a {{pcre}}) and returns the resulting strings within the quotation {{q}}. #}

{#op||strip||{{sl}}||{{s}}||
Returns {{s}}, which is set to {{sl}} with leading and trailing spaces removed.#} 

{#op||substr||{{s1}} {{i1}} {{i2}}||{{s2}}||
Returns a substring {{s2}} obtained by retriving {{i2}} characters starting from index {{i1}} within {{s1}}.#}

{#op||suffix||{{sl1}} {{sl2}}||{{s}}||
Appends {{sl2}} to {{sl1}}.#}

{#op||titleize||{{sl}}||{{s}}||
Returns a copy of {{sl}} in which the first character of each word is capitalized.#}

{#op||to-semver||{{d}}||{{s}}||
Given a a dictionary {{d}} containing a **major**, **minor**, and **patch** key/value pairs , it pushes a basic [SemVer](https://semver.org)-compliant string (with no additional labels) {{s}} on the stack.#}

{#op||uppercase||{{sl1}}||{{sl2}}||
Returns a copy of {{sl}} converted to uppercase.#}

