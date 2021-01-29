-----
content-type: "page"
title: "http Module"
-----
{@ _defs_.md || 0 @}

{#op||download||{{s1}} {{s2}}||{{none}}||
Downloads the contents of URL {{s1}} to the local file {{s2}}. #}

{#op||get-content||{{s1}}||{{s2}}||
Retrieves the contents of URL {{s1}} as {{s2}}.#}

{#op||request||{{d}}||{{res}}||
> Performs an HTTP request. Note that {{d}} is can be a standard (untyped) dictionary but its fields will be validated like if it was a {{req}}.
>
> > %sidebar%
> > Example
> > 
> > The following code constructs {{d}} and passes it to the **request** operator to perform an HTTP GET request to <http://httpbin.org/ip>:
> > 
> >     {}
> >       "GET" %method
> >       "http://httpbin.org/ip" %url
> >     request
 #}

{#op||start-server||{{d}}||{{none}}||
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
> >     ; Define the request handler
> >     (
> >       ; Assume there is a request on the stack, take it off and give it the name req
> >       :req
> >       ; Let's see what we got (print req to standard out)
> >       "THE REQUEST:" puts! req puts!
> >       ; The request is a dictionary, we retrieve the value for the key url, and give it the name url
> >       req /url :url
> >       "THE URL is '$1'." url quote % puts!
> >       ; Constuct response body
> >       (
> >         (("/datetime" url ==) (timestamp datetime))
> >         (("/timestamp" url ==) (timestamp string))
> >         (("/shutdown" url ==) ("Stopping server..." puts! stop-server))
> >         (("/" url ==) (
> >           ; this is a bit short, but works with Chrome, IE, Edge, Safari
> >           "<a href='/datetime'>datetime</a>, <a href='/timestamp'>timestamp</a>, <a href='/shutdown'>stop</a>"
> >         ))
> >         ((true) ("Invalid Request: $1" url quote %))
> >       ) case
> >       :body
> >       ; Prepare the response
> >       {} body %body
> >       dup puts!
> >     )
> >     ; The request handler is ready, give it the name handler
> >     =handler
> >     
> >     ; Create the parameter dictionary for the server
> >     {}
> >     handler %handler
> >     5555 %port
> >     
> >     ; Start server
> >     "Server started on port 5555." puts!
> >     "Press Ctrl+C to stop." puts!
> >     start-server
 #}

{#op||stop-server||{{none}}||{{none}}||
Stops the currently-running HTTP server. This operator should be used within an HTTP server handler quotation.#}