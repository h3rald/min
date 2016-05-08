import times, tables
import ../core/interpreter, ../core/utils

# Time

minsym "timestamp", i:
  i.push getTime().int.newVal

minsym "now", i:
  i.push epochTime().newVal

