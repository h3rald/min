# linenoise.h -- guerrilla line editing library against the idea that a
#  line editing lib needs to be 20,000 lines of C code.
# 
#  See linenoise.c for more information.
# 
#  ------------------------------------------------------------------------
# 
#  Copyright (c) 2010, Salvatore Sanfilippo <antirez at gmail dot com>
#  Copyright (c) 2010, Pieter Noordhuis <pcnoordhuis at gmail dot com>
# 
#  All rights reserved.
# 
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
# 
#   *  Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
# 
#   *  Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

{.compile: "vendor/linenoise/liblinenoise.c".}
{.push importc.}
when not(defined(LINENOISE_H)): 
  const 
    LINENOISE_H* = true
  when not(defined(NO_COMPLETION)): 
    type 
      linenoiseCompletions* = object 
        len*: csize
        cvec*: cstringArray
      linenoiseCompletionCallback* = proc (a: cstring, b: ptr linenoiseCompletions)

    #
    #  The callback type for tab completion handlers.
    # 
    #typedef void(linenoiseCompletionCallback)(const char *, linenoiseCompletions *);
    #
    #  Sets the current tab completion handler and returns the previous one, or NULL
    #  if no prior one has been set.
    # 
    proc linenoiseSetCompletionCallback*(a: linenoiseCompletionCallback): linenoiseCompletions;
    #
    #  Adds a copy of the given string to the given completion list. The copy is owned
    #  by the linenoiseCompletions object.
    # 
    proc linenoiseAddCompletion*(a2: ptr linenoiseCompletions; a3: cstring)
  #
  #  Prompts for input using the given string as the input
  #  prompt. Returns when the user has tapped ENTER or (on an empty
  #  line) EOF (Ctrl-D on Unix, Ctrl-Z on Windows). Returns either
  #  a copy of the entered string (for ENTER) or NULL (on EOF).  The
  #  caller owns the returned string and must eventually free() it.
  # 
  proc linenoise*(prompt: cstring): cstring
  #
  #  Activates password entry in future calls of linenoise(), i.e. user
  #  input will not be echoed back to the terminal during entry.
  # 
  const 
    LN_HIDDEN_NO* = (0)       # Fully visible entry.           
    LN_HIDDEN_ALL* = (1)      # Fully hidden, no echo at all   
    LN_HIDDEN_STAR* = (2)     # Hidden entry, echoing *'s back 
  proc linenoiseSetHidden*(enable: cint)
  #
  #  Activates normal entry in future calls of linenoise(), i.e. user
  #  input will again be echoed back to the terminal during entry.
  # 
  proc linenoiseGetHidden*(): cint
  #
  #  Adds a copy of the given line of the command history.
  # 
  proc linenoiseHistoryAdd*(line: cstring): cint
  #
  #  Sets the maximum length of the command history, in lines.
  #  If the history is currently longer, it will be trimmed,
  #  retaining only the most recent entries. If len is 0 or less
  #  then this function does nothing.
  # 
  proc linenoiseHistorySetMaxLen*(len: cint): cint
  #
  #  Returns the current maximum length of the history, in lines.
  # 
  proc linenoiseHistoryGetMaxLen*(): cint
  #
  #  Saves the current contents of the history to the given file.
  #  Returns 0 on success.
  # 
  proc linenoiseHistorySave*(filename: cstring): cint
  #
  #  Replaces the current history with the contents
  #  of the given file.  Returns 0 on success.
  # 
  proc linenoiseHistoryLoad*(filename: cstring): cint
  #
  #  Frees all history entries, clearing the history.
  # 
  proc linenoiseHistoryFree*()
  #
  #  Returns a pointer to the list of history entries, writing its
  #  length to *len if len is not NULL. The memory is owned by linenoise
  #  and must not be freed.
  # 
  proc linenoiseHistory*(len: ptr cint): cstringArray
  #
  #  Returns the number of display columns in the current terminal.
  # 
  proc linenoiseColumns*(): cint
  #
  #  Returns the number of display rows|lines in the current terminal.
  # 
  proc linenoiseLines*(): cint
