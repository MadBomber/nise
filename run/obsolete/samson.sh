#!/bin/sh

LD_LIBRARY_PATH=../lib:$LD_LIBRARY_PATH

echo $LD_LIBRARY_PATH:

mysql -u Samson Samson -e "delete Subscriber, Message from Subscriber, Message where Message.ID = Subscriber.MessageID and Message.JobID = 1;"
#mysql -u Samson -e "truncate Samson.Subscriber;"
#mysql -u Samson -e "truncate Samson.Message;"
mysql -u Samson Samson -e "Delete Model,Peer from Model,Peer where Peer.ID = Model.ID and Model.JobID = 1;"


rm -f output_*
#time ../SamsonPeer/peerd -j1 -kCtrlr -lAppCtrl -c8001 -m13 -n3 -o -dAPPBASE -p1 &
time ../SamsonPeer/peerd -j1 -kCtrlr -lSamModelCtrl -u1 -c8001 -m13 -n3 -o -dAPPBASE -p1 &


../SamsonPeer/peerd -j1 -kTARGET1  -lTarget -u1  -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTARGET2  -lTarget -u2  -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTARGET3  -lTarget -u3  -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kSURVRDR  -lSr -u1      -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTOC      -lTOC -u1     -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kMISSILE1 -lMissile -u1 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kMISSILE2 -lMissile -u2 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kMISSILE3 -lMissile -u3 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kTrkRadar -lTrkRadar -u1 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kLNCHR    -lLauncher -u1 -c8001 -o -dMODEL  &
../SamsonPeer/peerd -j1 -kEXEC     -lExecutive -u1 -c8001 -o -dMODEL -n3  &
../SamsonPeer/peerd -j1 -kVAT      -lVatLogData -u1 -c8001 &

