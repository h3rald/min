{@ _defs_.md || 0 @}

Quotations are the most important thing to understand in min. Besides being the data type used for lists, they are also used to delimit blocks of min code that is not going to be immediately executed. 

Consider for example the following min code which returns all the files present in the current folder:

     . ls (ftype 'file ==) filter

The symbol {#link-operator||seq||filter#} takes two quotations as arguments -- the first quotation on the stack is applied to all the elements of the second quotation on the stack, to determine which elements of the second quotation will be part of the resulting quotation. This is an example of how quotations can be used both as lists and programs.

Let's examine this program step-by-step:

{{fdlist => ("dir1" "dir2" file1.txt "file2.txt" "file3.md" "file4.md")}}
{{flist => ("file1.txt" "file2.txt" "file3.md" "file4.md")}}

<table>
  <tr>
    <th>Element</th><th>Stack</th><th>Explanation</th>
  </tr>
  <tr>
    <td>
      <code>.</code>
    </td>
    <td>
      <ol>
        <li><code>"/Users/h3rald/test"</code></li>
      <ol>
    </td>
    <td>
      The symbol <code>.</code> is pushed on the stack, and it is resolved to the full path to the current folder.
    </td>
  </tr>
  <tr>
    <td>
      <code>ls</code>
    </td>
    <td>
      <ol>
        <li><code>{{fdlist}}</code></li>
      </ol>
    </td>
    <td>
      The symbol <code>ls</code> is pushed on the stack, and a list containing all files and folders in the current folder is pushed on the stack.
    </td>
  </tr>
  <tr>
    <td>
      <code>(ftype 'file ==)</code>
    </td>
    <td>
      <ol>
        <li><code>(ftype 'file ==)</code></li>
        <li><code>{{fdlist}}</code></li>
      </ol>
    </td>
    <td>
      The quotation <code>(ftype 'file ==)</code> is pushed on the stack.
    </td>
  </tr>
  <tr>
    <td>
      <code>filter</code>
    </td>
    <td>
      <ol>
        <li><code>{{flist}}</code></li>
      </ol>
    </td>
    <td>
      The symbol <code>filter</code> is pushed on the stack, and an array containing only the files present in the current folder is pushed on the stack.
    </td>
  </tr>
</table>

> %tip%
> Tip
> 
> The {{#link-module||seq#}} provides several symbols to work with quotations in a functional way.

{#link-learn||variables||Variables#}
