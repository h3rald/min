import times, tables
import ../core/interpreter, ../core/utils

# Time

minsym "timestamp":
  i.push getTime().int.newVal

minsym "now":
  i.push epochTime().newVal

