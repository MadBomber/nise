#!/bin/sh

LD_LIBRARY_PATH=../lib:$LD_LIBRARY_PATH

echo $LD_LIBRARY_PATH:

mysql -u samson -e "truncate Samson.Subscriber;"
mysql -u samson -e "truncate Samson.Message;"
mysql -u samson -e "truncate Samson.Model;"

rm -f output_*

time ../SamsonPeer/peerd -j1 -kCtrlr -lSamModelCtrl -c8001 -m2 -p1 -o -dAPPBASE &
sleep 1

../SamsonPeer/peerd -j1 -kTARGET -lCmdTarget -c8001 -o &
