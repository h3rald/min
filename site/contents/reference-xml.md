-----
content-type: "page"
title: "xml Module"
-----
{@ _defs_.md || 0 @}

{#op||from-xml||{{sl}}||{{xnode}}||
> Returns an {{xnode}} representing an XML string representing an element or fragment.
> 
> > %sidebar%
> > Example
> >  
> > The following program:
> >
> >     "<a href='https://min-lang.org'>min web site</a>" from-xml  
> > returns the following:
> > 
> >     {
> >       {"https://min-lang.org" :href} :attributes
> >      ({"min web site" :text}) :children
> >      "a" :tag
> >      ;xml-element
> >     }
 #}

{#op||to-xml||{{xnode}}||{{s}}||
Returns a {{s}} representing an XML node. #}

{#op||xcdata||{{sl}}||{{xcdata}}||
Returns a {{xcdata}} representing an XML CDATA section. #}

{#op||xcomment||{{sl}}||{{xcomment}}||
Returns a {{xcomment}} representing an XML comment. #}

{#op||xelement||{{sl}}||{{xelement}}||
Returns a {{xelement}} representing an XML element (it will be an empty element with no attributes or children). #}

{#op||xentity||{{sl}}||{{xentity}}||
Returns a {{xentity}} representing an XML entity. #}

{#op||xquery||{{xelement}} {{sl}}||{{xelement}}||
> Returns an {{xelement}} representing the first element matching CSS the selector {{sl}}.
> 
> > %sidebar%
> > Example
> >  
> > The following program:
> >
> >     "<ul>
> >        <li class='test'>first</li>
> >        <li class='other'>second</li>
> >        <li class='test'>third</li>
> >     </ul>" 
> >     from-xml ".test" xquery
> > Returns the following:
> >
> >     {
> >       {"test" :class} :attributes 
> >       ({"first" :text}) :children 
> >       "li" :tag 
> >       ;xml-element
> >     }
 #}

{#op||xqueryall||{{xelement}} {{sl}}||{{xelement}}||
> Returns a list of {{xelement}} dictionaries representing all the elements matching CSS the selector {{sl}}.
> 
> > %sidebar%
> > Example
> >  
> > The following program:
> >
> >     "<ul>
> >        <li class='test'>first</li>
> >        <li class='other'>second</li>
> >        <li class='test'>third</li>
> >     </ul>" 
> >     from-xml ".test" xqueryall
> > Returns the following:
> >
> >     ({
> >       {"test" :class} :attributes 
> >       ({"first" :text}) :children 
> >       "li" :tag 
> >       ;xml-element
> >     }
> >     {
> >       {"test" :class} :attributes 
> >       ({"third" :text}) :children 
> >       "li" :tag 
> >       ;xml-element
> >     })
 #}

{#op||xtext||{{sl}}||{{xtext}}||
Returns a {{xtext}} representing an XML text node. #}
