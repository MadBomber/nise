#!/bin/sh
#######################################################################
###
##  File: hudson_step_01.sh
##  Desc: This is builds ISE as a full release.
##        The script is executed by Hudson within the context of the hudson user.
##  Loc:  $ISE_ROOT/build
#

# Hudson context is the pwd is at $WORKSPACE which is the $ISE_ROOT

rvm use 1.9.2
unset ISE_ROOT

cd $WORKSPACE

echo "############"
echo `pwd`
ls -alF
echo "############"

env | sort

echo "############"
source ./setup_symbols

echo "############"
iserelease.s

