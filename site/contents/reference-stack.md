-----
content-type: "page"
title: "stack Module"
-----
{@ _defs_.md || 0 @}

{#op||clear-stack||{{any}}||{{none}}||
Empties the stack.#}

{#op||cleave||{{a1}} ({{q}}{{0p}})||{{a0p}}||
> Applies each quotation contained in the first element to the second element {{a1}}.
> > %sidebar%
> > Example
> > 
> > The following program leaves 2 on the stack:
> > 
> > `(1 2 3) ((sum) (size)) cleave /`#}

{#op||cons||{{a1}} ({{a0p}})||({{a1}} {{a0p}})||
Prepends {{a1}} to the quotation on top of the stack.#}

{#op||dip||{{a1}} ({{a2}})||{{a0p}} {{a1}}||
Removes the first and second element from the stack, dequotes the first element, and restores the second element.#}

{#op||dup||{{a1}}||{{a1}} {{a1}}||
Duplicates the first element on the stack.#}

{#op||get-stack||{{none}}||({{a0p}})||
Puts a quotation containing the contents of the stack on the stack.#}

{#op||id||{{none}}||{{none}}||
Does nothing.#}

{#op||keep||{{a1}} {{q}}||{{a0p}} {{a1}}||
> Removes the first element from the stack, dequotes it, and restores the second element.
> > %sidebar%
> > Example
> > 
> > The following program leaves `5 3` on the stack:
> > 
> > `2 3 '+ keep` #}

{#op||nip||{{a1}} {{a2}}||{{a2}}||
Removes the second element from the stack.#}

{#op||over||{{a1}} {{a2}}||{{a1}} {{a2}} {{a1}}||
Pushes a copy of the second element on top of the stack.#}

{#op||pick||{{a1}} {{a2}} {{a3}}||{{a1}} {{a2}} {{a3}} {{a1}}||
Pushes a copy of the third element on top of the stack.#}

{#op||pop||{{any}}||{{none}}||
Removes the first element from the stack.#}

{#op||rolldown||{{a1}} {{a2}} {{a3}}||{{a2}} {{a3}} {{a1}}||
Moves the third element in first position, the second in third position and the the first in second position.#}

{#op||rollup||{{a1}} {{a2}} {{a3}}||{{a3}} {{a2}} {{a1}}||
Moves the third and second element into second and third position and moves the first element into third position.#}

{#op||set-stack||{{q}}||{{a0p}}||
Substitute the existing stack with the contents of {{q}}.#}

{#op||sip||{{q1}} {{q2}}||{{a0p}} {{q1}}||
Saves the {{q1}}, dequotes {{q2}}, and restores {{q1}}.#}

{#op||spread||{{a0p}} ({{q}}{{0p}})||{{a0p}}||
> Applies each quotation contained in the first element to each subsequent corresponding element.
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 4)` on the stack:
> > 
> > `(1 2) (3 4) ((0 get) (1 get)) spread` #}

{#op||swap||{{a1}} {{a2}}||{{a2}} {{a1}}||
Swaps the first two elements on the stack. #}

{#op||swons||({{a0p}}) {{a1}}||({{a1}} {{a0p}})||
Prepends {{a1}} to the quotation that follows it.#}