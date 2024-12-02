#!/bin/sh
#LD_LIBRARY_PATH+=../lib
#echo $LD_LIBRARY_PATH
cd ../dispatcherd
gnome-terminal -x ./dispatcherd -f xml/ise1.xml  &

