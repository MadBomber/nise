#!/bin/sh

LD_LIBRARY_PATH=../lib:$LD_LIBRARY_PATH

echo $LD_LIBRARY_PATH:

mysql -u Samson -e "truncate Samson.Subscriber;"
mysql -u Samson -e "truncate Samson.Message;"
#mysql -u Samson -e "truncate Samson.Peer;"
#mysql -u Samson -e "truncate Samson.Model;"


rm -f output_*
#time ../SamsonPeer/peerd -j1 -kCtrlr -lAppCtrl -c8001 -m13 -n3 -o -dAPPBASE -p1 &
time ../SamsonPeer/peerd -j1 -kCtrlr -lSamModelCtrl -c8001 -m13 -n3 -o -dAPPBASE -p1 &

sleep 1

ssh 138.209.52.142 "LD_LIBRARY_PATH=~/ise/trunk/lib:$LD_LIBRARY_PATH; ~/ise/trunk/SamsonPeer/peerd -j1 -kTARGET1  -lTarget -u1  -c8001 -o -dMODEL  &"

../SamsonPeer/peerd -j1 -kTARGET2  -lTarget -u2  -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTARGET3  -lTarget -u3  -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kSURVRDR  -lSr          -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTOC      -lTOC         -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kMISSILE1 -lMissile -u1 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kMISSILE2 -lMissile -u2 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kMISSILE3 -lMissile -u3 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTrkRadar -lTrkRadar    -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kLNCHR    -lLauncher    -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kEXEC     -lExecutive   -c8001 -o -dMODEL -n3  &
../SamsonPeer/peerd -j1 -kVAT      -lVatLogData  -c8001 &

