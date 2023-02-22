-----
content-type: "page"
title: "net Module"
-----
{@ _defs_.md || 0 @}

{#op||accept||{{sock1}} {{sock2}}||{{sock1}}||
Makes {{sock2}} (server) accept a connection from {{sock1}} (client). Returns the client socket {{sock1}} from which it will be possible to receive data from. #}

{#op||close||{{sock}}||{{none}}||
Closes a previously-opened socket. #}

{#op||connect||{{sock}} {{s}} {{i}}||{{sock}}||
> Connects socket {{sock}} to address {{s}} and port {{i}}.
> 
> > %sidebar%
> > Example
> > 
> > The following code shows how to send a message to a server running on localhost:7777. The message is passed as the first argument to the program.
> > 
> >     {} socket "localhost" 7777 connect :cli
> >     
> >     args 1 get :msg
> >     
> >     "Sending message \"$1\" to localhost:7777..." (msg) => % puts!
> >     
> >     cli "$1\n" (msg) => % send
> >     
> >     "Done." puts!
> >     
> >     cli close
 #}

{#op||listen||{{d}} {{sock1}}||{{sock2}}||
> Makes socket {{sock1}} listen to the specified address and port. {{d}} can be empty or contain any of the following properties, used to specify the address and port to listen to respectively.
> 
> address
> : The address to listen to (default: **0.0.0.0**).
> port
> : The port to listen to (default: **80**).
> 
> > %sidebar%
> > Example
> > 
> > The following code shows how to create a simple server that listens on port 7777, prints data received from clients, and exits when it receives the string `exit`:
> > 
> >     {} socket {"127.0.0.1" :address 7777 :port} listen :srv
> >     
> >     "Server listening on localhost:7777" puts!
> >     
> >     {} socket :cli
> >     "" :line
> >     (line "exit" !=)
> >     (
> >       srv cli accept #cli
> >       cli recv-line @line
> >       "Received: $1" (line) => % puts!
> >     ) while
> >     
> >     "Exiting..." puts!
> >     
> >     srv close
 #}

{#op||recv||{{sock}} {{i}}||{{s}}||
Waits to receive {{i}} characters from {{sock}} and returns the resulting data {{s}}.#}

{#op||recv-line||{{sock}}||{{s}}||
> Waits to receive a line of data from {{sock}} and returns the resulting data {{s}}. `""` is returned if {{sock}} is disconnected.
> 
> > %sidebar%
> > Example
> > 
> > The following code shows how to make a simple GET request to <http://httpbin.org/uuid> to receive a random UUID and display its response:
> > 
> > 
> >     {} socket "httpbin.org" 80 connect :cli
> >    
> >     cli "GET /uuid HTTP/1.1\r\nHost: httpbin.org\r\n\r\n" send
> >   
> >     cli recv-line puts :line
> >     (line "\}" match not) 
> >     (
> >       cli recv-line puts @line
> >     ) while
 #}

{#op||send||{{sock}} {{s}}||{{none}}||
Sends {{s}} to the connected socket {{sock}}. #}

{#op||socket||{{d}}||{{sock}}||
> Opens a new socket.
> 
> {{d}} can be empty or contain any of the following properties, used to specify the domain, type and protocol of the socket respectively.
> 
> domain
> : The socket domain. It can be set to one of the following values:
>   
>   *  **ipv4** (default): Internet Protocol version 4.
>   *  **ipv6**: Internet Protocol version 6.
>   *  **unix**: local Unix file {{no-win}}.
> type
> : The socket type. It can be set to one of the following values:
>  
>   * **stream** (default): Reliable stream-oriented service or Stream Socket.
>   * **dgram**: Datagram service or Datagram Socket.
>   * **raw**: Raw protocols atop the network layer.
>   * **seqpacket**: Reliable sequenced packet service.
> protocol
> : The socket protocol. It can be set to one of the following values:
> 
>   * **tcp** (default): Transmission Control Protocol.
>   * **udp**: User Datagram Protocol.
>   * **ipv4**: Internet Protocol version 4 {{no-win}}.
>   * **ipv6**: Internet Protocol version 6 {{no-win}}.
>   * **raw**: Raw IP Packets protocol {{no-win}}.
>   * **icmp**: Internet Control Message Protocol {{no-win}}.
 #}
