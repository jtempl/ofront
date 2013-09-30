#!/bin/bash
#
# compile an Oberon module <M>.Mod into a shared library lib<M>.so
#
# SYNOPSIS
#   ocl moduleName [ofrontOption [ccOption]]
#
# use single character "-" to skip ofrontOption
# example: ocl hello - -g

# translate <M>.Mod to <M>.c
ofront $1.Mod $2

# compile <M>.c to <M>.o
cc -c $3 $1.c

# link <M>.o into lib<M>.so
cc -shared -L. -lOberonV4 $1.o -o lib$1.so

# remove unnecessary files and show result
rm $1.c $1.o
ls -l lib$1.so
