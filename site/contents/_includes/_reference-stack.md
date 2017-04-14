{@ _defs_.md || 0 @}

{#op||dip||2 (1)||1 2||
Removes the first and second element from the stack, unquotes the first element, and restores the second element.#}

{#op||dup||1||1 1||
Duplicates the first element on the stack.#}

{#op||dupd||2 1||2 2 1||
Duplicates the second element on the stack.#}

{#op||id||{{null}}||{{null}}||
Does nothing.#}

{#op||k||(2) (1)||1||
K combinator; removes the second element from the stack and unquotes the first element on the stack.#}

{#op||newstack||{{null}}||{{null}}||
Empties the stack.#}

{#op||pop||\*||{{null}}||
Removes the first element from the stack.#}

{#op||popd||2 1||1||
Removes the second element from the stack.#}

{#op||popop||2 1||{{null}}||
Removes the first two elements from the stack.#}

{#op||rollup||3 2 1||1 2 3||
 Moves the third and second element into second and third position and moves the first element into third position.#}

{#op||stack||{{null}}||(\*)||
Returns a quotation containing the contents of the stack.#}

{#op||swap||2 1||1 2||
Swaps the first two elements on the stack. #}

{#op||unstack||(\*)||\*?||
Substitute the existing stack with the contents of {{q}}.#}

{#op||w||(2) (1)||(2) (2) 1||
W combinator; duplicates the second element from the stack and unquotes the first element on the stack.#}