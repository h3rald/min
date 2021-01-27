{{q => [quot](class:kwd)}}
{{q1 => [quot<sub>1</sub>](class:kwd)}}
{{q2 => [quot<sub>2</sub>](class:kwd)}}
{{q3 => [quot<sub>3</sub>](class:kwd)}}
{{q4 => [quot<sub>4</sub>](class:kwd)}}
{{1 => [<sub>1</sub>](class:kwd)}}
{{2 => [<sub>2</sub>](class:kwd)}}
{{3 => [<sub>3</sub>](class:kwd)}}
{{4 => [<sub>4</sub>](class:kwd)}}
{{e => [dict:error](class:kwd)}}
{{tinfo => [dict:timeinfo](class:kwd)}}
{{dstore => [dict:datastore](class:kwd)}}
{{d => [dict](class:kwd)}}
{{d1 => [dict<sub>1</sub>](class:kwd)}}
{{d2 => [dict<sub>2</sub>](class:kwd)}}
{{d0p => [dict<sub>\*</sub>](class:kwd)}}
{{flt => [flt](class:kwd)}}
{{i => [int](class:kwd)}}
{{i1 => [int<sub>1</sub>](class:kwd)}}
{{i2 => [int<sub>2</sub>](class:kwd)}}
{{i3 => [int<sub>3</sub>](class:kwd)}}
{{n => [num](class:kwd)}}
{{n1 => [num<sub>1</sub>](class:kwd)}}
{{n2 => [num<sub>2</sub>](class:kwd)}}
{{n3 => [num<sub>3</sub>](class:kwd)}}
{{any => [a](class:kwd)}}
{{a1 => [a<sub>1</sub>](class:kwd)}}
{{a2 => [a<sub>2</sub>](class:kwd)}}
{{a3 => [a<sub>3</sub>](class:kwd)}}
{{a0p => [a<sub>\*</sub>](class:kwd)}}
{{s0p => [str<sub>\*</sub>](class:kwd)}}
{{s => [str](class:kwd)}}
{{s1 => [str<sub>1</sub>](class:kwd)}}
{{s2 => [str<sub>2</sub>](class:kwd)}}
{{s3 => [str<sub>3</sub>](class:kwd)}}
{{s4 => [str<sub>4</sub>](class:kwd)}}
{{b => [bool](class:kwd)}}
{{b1 => [bool<sub>1</sub>](class:kwd)}}
{{b2 => [bool<sub>2</sub>](class:kwd)}}
{{b3 => [bool<sub>3</sub>](class:kwd)}}
{{01 => [<sub>?</sub>](class:kwd)}}
{{0p => [<sub>\*</sub>](class:kwd)}}
{{1p => [<sub>\+</sub>](class:kwd)}}
{{sl => [&apos;sym](class:kwd)}}
{{sl1 => [&apos;sym<sub>1</sub>](class:kwd)}}
{{sl2 => [&apos;sym<sub>2</sub>](class:kwd)}}
{{f => [false](class:kwd)}} 
{{t => [true](class:kwd)}}
{{null => [null](class:kwd)}}
{{none => &#x2205;}}
{{no-win => (not supported on Windows systems)}}
{{help => [dict:help](class:kwd)}}
{{sock => [dict:socket](class:kwd)}}
{{url => [url](class:kwd)}}
{{req => [request](class:kwd)}}
{{res => [response](class:kwd)}}
{{sock1 => [dict:socket<sub>1</sub>](class:kwd)}}
{{sock2 => [dict:socket<sub>2</sub>](class:kwd)}}
{{m => _min_}}

{{sgregex => [sgregex](https://github.com/snake5/sgregex).}}

{#op => 
<a id="op-$1"></a>
## $1 

> %operator%
> [ $2 **&rArr;** $3](class:kwd)
> 
> $4
 #}

{#alias => 
## $1 

> %operator%
> [ $1 **&rArr;** $2](class:kwd)
> 
> See [$2](#op-$2).
 #}

{#sig => 
## $1 [](class:sigil)

> %operator%
> [ $1{{s}} **&rArr;** {{s}} $2](class:kwd)
> 
> See [$2](#op-$2).
 #}

{# link-page => [$2](/$1/) #}

{# link-module => [`$1` Module](/reference-$1/) #}

{# link-operator => [`$2`](/reference-$1#op-$2) #}

{# link-learn => &rarr; Continue to [*$2*](/learn-$1) #}

{{ learn-links =>
> %tip%
> Quick Links
> 
> * [Data Types](/learn-data-types)
> * [Operators](/learn-operators)
> * [Quotations](/learn-quotations)
> * [Definitions](/learn-definitions)
> * [Scopes](/learn-scopes)
> * [Control Flow](/learn-control-flow)
> * [Shell](/learn-shell)
> * [Extending min](/learn-extending)
}}

{{guide-download => 
> %tip%
> Tip
> 
> A printable, self-contained guide containing more or less the same content of this web site can be downloaded from [here](https://h3rald.com/min/Min_DeveloperGuide.htm). }}
