% min Language Developer Guide
% Fabio Cevasco
% -

<style>
.reference-title {
  font-size: 120%;  
  font-weight: 600;
}
.min-terminal {
    -moz-background-clip: padding;
    -webkit-background-clip: padding-box;
    background-clip: padding-box;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
    border-radius: 3px;
    margin: 10px auto;
    padding: 2px 4px 0 4px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    text-shadow: 0 1px 0 rgba(255, 255, 255, 0.8);
    color: #eee;
    background-color: #222;
    border: 1px solid #ccc;
    white-space: pre;
    padding: 0 3px;
    border: 2px solid #999;
    border-top: 10px solid #999;
}
.min-terminal p {
  margin: 0 auto;  
}
.min-terminal p, .min-terminal p:first-child {
    margin-top: 0;
    margin-bottom: 0;
    text-shadow: none;
    font-weight: normal;
    font-family: "Source Code Pro", "Monaco", "DejaVu Sans Mono", "Courier New", monospace;
    font-size: 85%;
    color: #eee;
}
</style>

## About min

{@ site/contents/_includes/_about.md || 1 @}

## Getting Started

{@ site/contents/_includes/_download.md || 1 @}

## Learning the min Language

{@ site/contents/_includes/_learn.md || 1 @}

### Data Types

{@ site/contents/_includes/_learn-data-types.md || 2 @}

### Quotations

{@ site/contents/_includes/_learn-quotations.md || 2 @}

### Operators 

{@ site/contents/_includes/_learn-operators.md || 2 @}

### Definitions

{@ site/contents/_includes/_learn-definitions.md || 2 @}

### Control Flow

{@ site/contents/_includes/_learn-control.flow.md || 2 @}

## Using the min Shell

{@ site/contents/_includes/_learn-shell.md || 1 @}

## Reference

{@ site/contents/_includes/_reference.md || 1 @}


### `lang` Module

{@ site/contents/_includes/_reference-lang.md || 1 @}

### `stack` Module

{@ site/contents/_includes/_reference-stack.md || 1 @}

### `seq` Module

{@ site/contents/_includes/_reference-seq.md || 1 @}

### `io` Module

{@ site/contents/_includes/_reference-io.md || 1 @}

### `fs` Module

{@ site/contents/_includes/_reference-fs.md || 1 @}

### `logic` Module

{@ site/contents/_includes/_reference-logic.md || 1 @}

### `str` Module

{@ site/contents/_includes/_reference-str.md || 1 @}

### `sys` Module

{@ site/contents/_includes/_reference-sys.md || 1 @}

### `num` Module

{@ site/contents/_includes/_reference-num.md || 1 @}

### `time` Module

{@ site/contents/_includes/_reference-time.md || 1 @}

### `crypto` Module

{@ site/contents/_includes/_reference-crypto.md || 1 @}





{#op => 
<a id="op-$1"></a>
[$1](class:reference-title)

> %operator%
> [ $2 **&rArr;** $3](class:kwd)
> 
> $4
 #}


{#alias => 
[$1](class:reference-title)

> %operator%
> [ $1 **&rArr;** $2](class:kwd)
> 
> See [$2](#op-$2).
 #}

{#sig => 
[$1](class:reference-title) [](class:sigil)

> %operator%
> [ $1{{s}} **&rArr;** {{s}} $2](class:kwd)
> 
> See [$2](#op-$2).
 #}

{# link-page => $2 #}

{# link-module => [`$1` Module](#<code>$1</code>-Module) #}

{# link-operator => [`$2`](#op-$2) #}

{# link-learn => #}

{{learn-links =>   }}

{{guide-download =>   }}
