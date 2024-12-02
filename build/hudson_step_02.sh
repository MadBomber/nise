#!/bin/sh
#######################################################################
###
##  File: hudson_step_02.sh
##  Desc: Counts Lines of Source Code using the SLOCcount tool.
##        The script is executed by Hudson within the context of the hudson user.
##  Loc:  $ISE_ROOT/build
#

# Hudson context is the pwd is at $WORKSPACE which is the $ISE_ROOT

echo "Counting Lines of Source Code ..."
sloccount --wide --details $WORKSPACE | fgrep -v .svn > $WORKSPACE/sloccount.sc

