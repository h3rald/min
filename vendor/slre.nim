#
#  Copyright (c) 2004-2005 Sergey Lyubka <valenok@gmail.com>
#  All rights reserved
# 
#  "THE BEER-WARE LICENSE" (Revision 42):
#  Sergey Lyubka wrote this file.  As long as you retain this notice you
#  can do whatever you want with this stuff. If we meet some day, and you think
#  this stuff is worth it, you can buy me a beer in return.
# 
#
#  This is a regular expression library that implements a subset of Perl RE.
#  Please refer to http://slre.sourceforge.net for detailed description.
# 
#  Usage example (parsing HTTP request):
# 
#  struct slre	slre;
#  struct cap	captures[4 + 1];  // Number of braket pairs + 1
#  ...
# 
#  slre_compile(&slre,"^(GET|POST) (\S+) HTTP/(\S+?)\r\n");
# 
#  if (slre_match(&slre, buf, len, captures)) {
# 	printf("Request line length: %d\n", captures[0].len);
# 	printf("Method: %.*s\n", captures[1].len, captures[1].ptr);
# 	printf("URI: %.*s\n", captures[2].len, captures[2].ptr);
#  }
# 
#  Supported syntax:
# 	^		Match beginning of a buffer
# 	$		Match end of a buffer
# 	()		Grouping and substring capturing
# 	[...]		Match any character from set
# 	[^...]		Match any character but ones from set
# 	\s		Match whitespace
# 	\S		Match non-whitespace
# 	\d		Match decimal digit
# 	\r		Match carriage return
# 	\n		Match newline
# 	+		Match one or more times (greedy)
# 	+?		Match one or more times (non-greedy)
# 	*		Match zero or more times (greedy)
# 	*?		Match zero or more times (non-greedy)
# 	?		Match zero or once
# 	\xDD		Match byte with hex value 0xDD
# 	\meta		Match one of the meta character: ^$().[*+?\
# 

{.compile: "vendor/slre/libslre.c".}
#
#  Compiled regular expression
# 
type 
  slre* = object 
    code*: array[256, cuchar]
    data*: array[256, cuchar]
    code_size*: cint
    data_size*: cint
    num_caps*: cint         # Number of bracket pairs	
    anchored*: cint         # Must match from string start	
    err_str*: cstring       # Error string			
  
#
#  Captured substring
# 
type 
  cap* = object 
    value*: cstring           # Pointer to the substring	
    len*: cint              # Substring length		

#
#  Compile regular expression. If success, 1 is returned.
#  If error, 0 is returned and slre.err_str points to the error message. 
# 
proc slre_compile(a2: ptr slre; re: cstring): cint {.importc.}
#
#  Return 1 if match, 0 if no match. 
#  If `captured_substrings' array is not NULL, then it is filled with the
#  values of captured substrings. captured_substrings[0] element is always
#  a full matched substring. The round bracket captures start from
#  captured_substrings[1].
#  It is assumed that the size of captured_substrings array is enough to
#  hold all captures. The caller function must make sure it is! So, the
#  array_size = number_of_round_bracket_pairs + 1
# 
proc slre_match(a2: ptr slre; buf: cstring; buf_len: cint; 
                 captured_substrings: openarray[cap]): cint {.importc.}

# High level API
from strutils import contains, replace, parseInt
from sequtils import delete

proc match*(s: string, re: string): seq[string] =
  var rawre = cast[ptr slre](alloc0(sizeof(slre)))
  if slre_compile(rawre, re) == 1:
    var matches:array[10, cap]
    if rawre.slre_match(s.cstring, s.len.cint, matches) == 1:
      var res = newSeq[string](0)
      for i in items(matches):
        if i.value != nil:
          var str = $(i.value)
          res.add str.substr(0, i.len-1)
      return res
    else:
      return newSeq[string](0)
  else:
    raise newException(ValueError, $(rawre.err_str))

proc gsub*(s_find: string, re: string, s_replace): string =
  var matches = s_find.match(re)
  if matches.len > 0:
    var res = s_find.replace(matches[0], s_replace)
    if matches.len > 1:
      # Replace captures
      var caps = res.match("\\$(\\d)")
      if caps.len > 1:
        # Remove first (global) match
        caps.delete(0, 0)
        for c in caps:
          var ci = parseInt(c)
          # Replace $-placeholders with captures
          while res.contains("$"&c):
            res = res.replace("$"&c, matches[ci])
    return res
  else:
    return s_find
