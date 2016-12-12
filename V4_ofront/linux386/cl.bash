#!/bin/bash
#
# This script is called by the command ocl for compiling and linking an Oberon
# module <M> from <M>.c into a shared library lib<outname>.so or, 
# if the option -m is specified, into an executable file named <outname>.
#
# SYNOPSIS
#   cl.bash M outname options ccOptions
#
#   options = "-" {"m" | "V" | "G" | "O"}
#   ccOptions = quoted string passed to cc
#     m    compile into executable main program
#     V    verbose mode
#     G    generate debug symbols
#     O    optimize generated code

if [[ $# != 4 ]]; then
  echo "cl.bash: illegal number of arguments"
  exit 1
else
  opt=""
  if [[ $3 =~ .*G.* ]]; then
	opt="$opt -g"
  fi
  if [[ $3 =~ .*O.* ]]; then
	opt="$opt -O"
  fi
  if [[ $3 =~ .*m.* ]]; then
    # compile and link <M>.c into executable
    rm -f $2
    if [[ $3 =~ .*V.* ]]; then
      echo "rm -f $2"
      echo "cc $opt $1.c -I$OFRONT_HOME/V4_ofront -o $2 -L. -L$OFRONT_HOME/lib $4"
    fi
    cc $opt $1.c -I$OFRONT_HOME/V4_ofront -o $2 -L. -L$OFRONT_HOME/lib $4
  else
    # compile and link <M>.c into shared library lib<M>.so
    rm -f lib$2.so
    if [[ $3 =~ .*V.* ]]; then
      echo "rm -f lib$2.so"
      echo "cc $opt $1.c -I$OFRONT_HOME/V4_ofront -shared -o lib$2.so -L. -L$OFRONT_HOME/lib $4"
    fi
    cc $opt $1.c -I$OFRONT_HOME/V4_ofront -shared -o lib$2.so -L. -L$OFRONT_HOME/lib $4
  fi
fi
