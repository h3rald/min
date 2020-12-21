-----
content-type: "page"
title: "dstore Module"
-----
{@ _defs_.md || 0 @}

{#op||dsdelete||{{datoee}} {{sl}}||{{dstore}}||
Removes an item from the datastore {{dstore}}. The item is uniquely identified by {{sl}}, which contains the collection containing the item and the item id, separated by a forward slash (/). Puts the reference to the modified datastore back on tbe stack.
#}

{#op||dsget||{{dstore}} {{sl}}||{{d}}||
Retrieves item {{d}} from datastore {{dstore}}. {{d}} is retrieved by specifying {{sl}}, which contains the collection containing the item and the item id, separated by a forward slash (/).
#}

{#op||dsinit||{{sl}}||{{dstore}}||
Initializes a bew datastore by creating the {{sl}} JSON file. Puts the datastore instance on the stack. #}

{#op||dspost||{{dstore}} {{sl}} {{d}}||{{dstore}}||
Adds the dictionary {{d}} to the datastore {{dstore}} inside collection {{sl}}, generating and adding a unique **id** field to {{d}}. If the collection {{sl}} does not exist it is created. Puts the reference to the modified datastore back on tbe stack.
#}

{#op||dsput||{{dstore}} {{sl}} {{d}}||{{dstore}}||
Adds the dictionary {{d}} to the datastore {{dstore}}. {{sl}} contains the collection where {{d}} will be placed and the id of {{d}}, separated by a forward slash (/). If the collection {{sl}} does not exist it is created. Puts the reference to the modified datastore back on tbe stack.
#}

{#op||dsquery||{{dstore}} {{sl}} {{q}}||({{d0p}})||
> Retrieves a quotation of dictionaries from the collection {{sl}} of datastore {{dstore}} obtained by applying {{q}} as a filter to each item of the collection, picking only the elements that match the filter.
>
> > %sidebar%
> > Example
> >
> > Assuming that **ds** is a datastore, the following program retrieves all elements of teh collection **posts** whose author field is set to "h3rald":
> >      ds "posts" (/author "h3rald" ==) dsquery
#}

{#op||dsread||{{sl}}||{{dstore}}||
Reads the previously-created datastore from the file {{sl}} and puts the resulting datastore instance on the stack.
#}

{#op||dswrite||{{dstore}}||{{dstore}}||
Writes the contents of the datastore {{dstore}} to the filesystem.
#}


