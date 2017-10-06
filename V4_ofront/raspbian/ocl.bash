#!/bin/bash
#
# compile an Oberon module <M>.Mod into a shared library lib<M>.so
#
# SYNOPSIS
#   ocl.bash moduleName [ofrontOptions [ccOptions]]

if [ -z "$1" ]; then
  echo "Compile an Oberon module <M>.Mod into a shared library lib<M>.so."
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
  ofront $1.Mod $2
  if [ -r $1.c ]; then
    # compile and link <M>.c into lib<M>.so
    rm -f lib$1.so
    cc $1.c -I$OFRONT_HOME/V4_ofront -shared -o lib$1.so -L. -L$OFRONT_HOME/lib -lOberonV4 $3
    # remove intermediate file(s) and show result
    rm $1.c
    ls -l lib$1.so
  fi
fi
