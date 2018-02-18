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

{#op||start-server||{{d}}||{{null}}||
> Starts an HTTP server based on the configuration provided in {{d}}.
> 
> {{d}} is a dictionary containing the following keys:
> 
> address
> : The address to bind the server to (default: **127.0.0.1**).
> port
> : The port to bind the server to.
> handler
> : A quotation with the following signature, used to handle all incoming requests: [{{req}} &rArr; {{res}}](class:kwd)
> 
> > %sidebar%
> > Example
> > 
> > The following program starts a very simple HTTP server that can display the current timestamp or date and time in ISO 8601 format:
> > 
> >     (
> >      =req
> >      req /url :url
> >      ;Set response body
> >      "Invalid Request: $1" (url) => % :body
> >      ("/datetime" url ==) (
> >       timestamp datetime @body
> >      ) when
> >      ("/timestamp" url ==) (
> >        timestamp string @body
> >      ) when
> >      ("/shutdown" url ==) (
> >       "Stopping server..." puts!
> >       stop-server
> >      ) when
> >      ;Prepare response
> >      () (
> >       (body %body)
> >      ) tap 
> >     ) =handler
> > 
> >     ;Start server
> >     "Server started on port 5555." puts!
> >     "Press Ctrl+C to stop." puts!
> >     () (
> >      (handler %handler)
> >      (5555 %port)
> >     ) tap start-server
 #}

{#op||stop-server||{{null}}||{{null}}||
Stops the currently-running HTTP server. This operator should be used within an HTTP server handler quotation.#}
