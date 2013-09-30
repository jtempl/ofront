#!/bin/bash

if [ -z "$OFRONT_HOME" ]; then
  OFRONT_HOME=.
  echo "OFRONT_HOME set to ."
fi
export OBERON=.:$OFRONT_HOME/V4_ofront:$OFRONT_HOME/V4:$OFRONT_HOME/fonts
export LD_LIBRARY_PATH=$OFRONT_HOME/lib

$OFRONT_HOME/bin/oberon $* &
