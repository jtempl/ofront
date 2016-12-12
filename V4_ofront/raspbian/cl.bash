#!/bin/bash
#
# compile an Oberon module <M>.c into a shared library lib<outname>.so
# or, if the option -m is specified, into an executable file <outname>
#
# SYNOPSIS
#   cl.bash moduleName outname options ccOptions

if [ -z "$1" ]; then
  echo "Compile an Oberon module <M>.c into a shared library lib<outname>.so"
  echo "or, if the option -m is specified, into an executable file <outname>."
  echo "ccOptions must be enclosed in quotes."
  echo
  echo "Usage: $0 moduleName outname options ccOptions"
  echo "options = -mgO   where m is for main, g for debug and O for optimze"
  echo
  echo "Examples:"
  echo "  " $0 MyModule Oberon_MyModule -g "\""-g -Lmypath -lOberon_MyImport1"\""
  echo "  " $0 MyMainModule Main -g "\""-g -Lmypath -lOberon_MyImport1"\"" -m
else
  if [[ $3 =~ .*m.* ]]; then
    # compile and link <M>.c into executable
    rm -f $2
    cc $1.c -I$OFRONT_HOME/V4_ofront -g -o $2 -L. -L$OFRONT_HOME/lib $4
  else
    # compile and link <M>.c into shared library lib<M>.so
    rm -f lib$2.so
    cc $1.c -I$OFRONT_HOME/V4_ofront -g -shared -o lib$2.so -L. -L$OFRONT_HOME/lib $4
  fi
fi
