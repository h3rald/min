{@ _defs_.md || 0 @}

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
Removes the first and second element from the stack, unquotes the first element, and restores the second element.#}

{#op||dup||{{a1}}||{{a1}} {{a1}}||
Duplicates the first element on the stack.#}

{#op||dupd||{{a1}} {{a2}}||{{a1}} {{a1}} {{a2}}||
Duplicates the second element on the stack.#}

{#op||id||{{null}}||{{null}}||
Does nothing.#}

{#op||k||{{a1}} ({{a2}})||{{a0p}}||
K combinator; removes the second element from the stack and unquotes the first element on the stack.#}

{#op||keep||{{a1}} {{q}}||{{a0p}} {{a1}}||
> Applies each quotation contained in the first element to each subsequent corresponding element.
> > %sidebar%
> > Example
> > 
> > The following program leaves `5 3` on the stack:
> > 
> > `2 3 '+ keep` #}

{#op||newstack||{{null}}||{{null}}||
Empties the stack.#}

{#op||over||{{a1}} {{a2}}||{{a1}} {{a2}} {{a1}}||
Pushes a copy of the second element on top of the stack.#}

{#op||pick||{{a1}} {{a2}} {{a3}}||{{a1}} {{a2}} {{a3}} {{a1}}||
Pushes a copy of the third element on top of the stack.#}

{#op||pop||{{any}}||{{null}}||
Removes the first element from the stack.#}

{#op||popd||{{a1}} {{a2}}||{{a2}}||
Removes the second element from the stack.#}

{#op||popop||{{a1}} {{a2}}||{{null}}||
Removes the first two elements from the stack.#}

{#op||rolldown||{{a1}} {{a2}} {{a3}}||{{a2}} {{a3}} {{a1}}||
Moves the third element in first position, the second in third position and the the first in second position.#}

{#op||rollup||{{a1}} {{a2}} {{a3}}||{{a3}} {{a2}} {{a1}}||
Moves the third and second element into second and third position and moves the first element into third position.#}

{#op||sip||{{a1}} ({{a2}})||{{a0p}} {{a1}}||
Saves the {{a1}}, unquotes {{a2}}, and restores {{a1}}.#}

{#op||spread||{{a0p}} ({{q}}{{0p}})||{{a0p}}||
> Applies each quotation contained in the first element to each subsequent corresponding element.
> > %sidebar%
> > Example
> > 
> > The following program leaves `(1 4)` on the stack:
> > 
> > `(1 2) (3 4) ((0 get) (1 get)) spread` #}

{#op||stack||{{null}}||({{a0p}})||
Returns a quotation containing the contents of the stack.#}

{#op||swap||{{a1}} {{a2}}||{{a2}} {{a1}}||
Swaps the first two elements on the stack. #}

{#op||swapd||{{a1}} {{a2}} {{a3}}||{{a2}} {{a1}} {{a3}}||
Swaps the second and third elements on the stack. #}

{#op||swons||({{a0p}}) {{a1}}||({{a1}} {{a0p}})||
Prepends {{a1}} to the quotation that follows it.#}

{#op||unstack||{{q}}||{{a0p}}||
Substitute the existing stack with the contents of {{q}}.#}


