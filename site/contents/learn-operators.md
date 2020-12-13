-----
content-type: "page"
title: "Learn: Operators"
-----
{@ _defs_.md || 0 @}

Every min program needs _operators_ to:

* Manipulate elements on the stack
* Perform operations on data
* Provide side effects (read/print to standard input/output/files, etc.)

There are two types of operators: _symbols_ and _sigils_.

_Symbols_ are the most common type of operator. A min symbol is a single word that is either provided by one of the predefined min {#link-page||reference||modules#} like `dup` or `.` or defined by the user. User-defined symbols must:

* Start with a letter or an underscore (\_).
* Contain zero or more letters, numbers and/or any of the following characters: `/ ! ? + * . _ -`

It is possible to define symbols using the {#link-operator||lang||define#} symbol. The following min program defines a new symbol called square that duplicates the first element on the stack and multiplies the two elements:

     (dup *) "square" define

Besides symbols, you can also define sigila. min provides a set of predefined _sigils_ as abbreviations for for commonly-used symbols. For example, the previous definition could be rewritten as follows using sigils:

     (dup *) :square

A sigil like `:` can be prepended to a double-quoted string or a single word (with no spaces) which will be treated as a string instead of using the corresponding symbol. 

For example, the following executes the command `ls -al` and pushes the command return code on the atack:

     !"ls -al"`

Currently min provides the following sigils:

+
: Alias for {#link-operator||lang||module#}.
~
: Alias for {#link-operator||lang||delete#}.
'
: Alias for {#link-operator||lang||quote#}.
\:
: Alias for {#link-operator||lang||define#}. 
^
: Alias for {#link-operator||lang||call#}. 
@
: Alias for {#link-operator||lang||bind#}. 
>
: Alias for {#link-operator||lang||save-symbol#}. 
<
: Alias for {#link-operator||lang||load-symbol#}. 
&#61;
: Alias for {#link-operator||lang||quote-bind#}. 
\#
: Alias for {#link-operator||lang||quote-define#}. 
/
: Alias for {#link-operator||dict||dget#}. 
%
: Alias for {#link-operator||dict||dset#}. 
?
: Alias for {#link-operator||dict||dhas?#}.
!
: Alias for {#link-operator||sys||system#}.
&
: Alias for {#link-operator||sys||run#}.
$
: Alias for {#link-operator||sys||get-env#}. 

Besides system sigils, you can also create your own sigils. Unlike system sigils however, user defined sigils:

* have the same character restricrions as symbols
* can only be prepended to double-quoted strings
* can be unsealed, deleted, redefined, and sealed.

Sigils can be a very powerful construct and a way to reduce boulerplate code: you can define a sigil to use as you would use any symbol which requires a single string or quoted symbol on the stack.

Consider the following example:

     'from-json 'j define-sigil
     
This will define a `j` sigil that will parse any string as JSON and convert it to its corresponding min representation.

{#link-learn||quotations||Quotations#}
