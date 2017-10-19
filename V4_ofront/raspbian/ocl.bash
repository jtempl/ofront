#!/bin/bash
#
# compile an Oberon module <M>.Mod into a shared library lib<M>.so
# or, if ofront option -m is specified, into an executable file <M>
#
# SYNOPSIS
#   ocl.bash moduleName [ofrontOptions [ccOptions]]

if [ -z "$1" ]; then
  echo "Compile an Oberon module <M>.Mod into a shared library lib<M>.so"
  echo "or, if ofront option -m is specified, into an executable file <M>."
  echo
  echo Usage: $0 moduleName [ofrontOptions [ccOptions]]
  echo
  echo Use single character - or "\"\"" to skip ofrontOptions.
  echo Examples:
  echo "  " $0 hello - -g
  echo "  " $0 MyModule -s "\""-g -Lmypath -lMyImport1 -lMyImport2"\""
  echo "  " $0 TestPi -s "\""-g -lWiringPi"\""
else
  # translate <M>.Mod to <M>.c
  rm -f $1.c
  $OFRONT_HOME/bin/ofront $1.Mod $2
  if [ -r $1.c ]; then
    if [[ $2 =~ .*m.* ]]; then
      # compile and link <M>.c into executable <M>
      rm -f $1
      cc $1.c -I$OFRONT_HOME/V4_ofront -o $1 -L. -L$OFRONT_HOME/lib -lOberonV4 $3
      # show result
      ls -l $1
    else
      # compile and link <M>.c into lib<M>.so
      rm -f lib$1.so
      cc $1.c -I$OFRONT_HOME/V4_ofront -shared -o lib$1.so -L. -L$OFRONT_HOME/lib -lOberonV4 $3
      # show result
      ls -l lib$1.so
    fi
  fi
fi
