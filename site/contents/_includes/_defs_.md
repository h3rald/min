{{q => [quot](class:kwd)}}
{{q1 => [quot<sub>1</sub>](class:kwd)}}
{{q2 => [quot<sub>2</sub>](class:kwd)}}
{{q3 => [quot<sub>3</sub>](class:kwd)}}
{{q4 => [quot<sub>4</sub>](class:kwd)}}
{{1 => [<sub>1</sub>](class:kwd)}}
{{2 => [<sub>2</sub>](class:kwd)}}
{{3 => [<sub>3</sub>](class:kwd)}}
{{4 => [<sub>4</sub>](class:kwd)}}
{{e => [err](class:kwd)}}
{{tinfo => [tinfo](class:kwd)}}
{{d => [dict](class:kwd)}}
{{d1 => [dict<sub>1</sub>](class:kwd)}}
{{d2 => [dict<sub>2</sub>](class:kwd)}}
{{flt => [float](class:kwd)}}
{{i => [int](class:kwd)}}
{{i1 => [a<sub>1</sub>](class:kwd)}}
{{i2 => [a<sub>2</sub>](class:kwd)}}
{{i3 => [a<sub>3</sub>](class:kwd)}}
{{n => [num](class:kwd)}}
{{n1 => [num<sub>1</sub>](class:kwd)}}
{{n2 => [num<sub>2</sub>](class:kwd)}}
{{n3 => [num<sub>3</sub>](class:kwd)}}
{{any => [a](class:kwd)}}
{{a1 => [a<sub>1</sub>](class:kwd)}}
{{a2 => [a<sub>2</sub>](class:kwd)}}
{{a3 => [a<sub>3</sub>](class:kwd)}}
{{a0p => [a<sub>\*</sub>](class:kwd)}}
{{s0p => [string<sub>\*</sub>](class:kwd)}}
{{s => [string](class:kwd)}}
{{s1 => [string<sub>1</sub>](class:kwd)}}
{{s2 => [string<sub>2</sub>](class:kwd)}}
{{s3 => [string<sub>3</sub>](class:kwd)}}
{{s4 => [string<sub>4</sub>](class:kwd)}}
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
{{null => &#x2205;}}
{{m => _min_}}

{{sgregex => [sgregex](https://github.com/snake5/sgregex).}}

{#op => 
<a id="op-$1"></>
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

{# link-module => [`$1` Module](/reference-$1/) #}

{# link-operator => [`$2`](/reference-$1/$2) #}

