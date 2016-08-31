{.compile: "linenoise/libwin32fixes.c".}
{.compile: "linenoise/liblinenoise.c".}

type 
  linenoiseCompletions* = object 
    len*: csize
    cvec*: cstringArray
  linenoiseCompletionCallback* = proc (a: cstring, b: ptr linenoiseCompletions) {.cdecl.}

const 
  LN_HIDDEN_NO* = (0)       # Fully visible entry.           
  LN_HIDDEN_ALL* = (1)      # Fully hidden, no echo at all   
  LN_HIDDEN_STAR* = (2)     # Hidden entry, echoing *'s back 

{.push importc.}
{.push cdecl.}
#
#  The callback type for tab completion handlers.
# 
#typedef void(linenoiseCompletionCallback)(const char *, linenoiseCompletions *);
#
#  Sets the current tab completion handler and returns the previous one, or NULL
#  if no prior one has been set.
# 
proc linenoiseSetCompletionCallback*(a: linenoiseCompletionCallback);
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
