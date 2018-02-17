-----
content-type: "page"
title: "http Module"
-----
{@ _defs_.md || 0 @}

{#op||download||{{s1}} {{s2}}||{{null}}||
Downloads the contents of URL {{s1}} to the local file {{s2}}. #}

{#op||get-content||{{s1}}||{{s2}}||
Retrieves the contents of URL {{s1}} as {{s2}}.#}

{#op||request||{{req}}||{{res}}||
> Performs an HTTP request.
> 
> > %sidebar%
> > Example
> > 
> > The following code constructs a {{req}} dictionary using the **tap** operator and passes it to the **request** operator to perform an HTTP GET request to <http://httpbin.org/ip>:
> > 
> >     () (
> >       ("GET" %method)
> >       ("http://httpbin.org/ip" %url)
> >     ) tap request
 #}

