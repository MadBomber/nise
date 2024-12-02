#!/bin/sh

#LD_LIBRARY_PATH=../lib:$LD_LIBRARY_PATH
#echo $LD_LIBRARY_PATH:

mysql -u Samson -e "truncate Samson.Subscriber;"
mysql -u Samson -e "truncate Samson.Message;"
mysql -u Samson -e "delete from Samson.Peer;"
mysql -u Samson -e "delete from Samson.Model;"


cd /home/ise/ise/trunk/dispatcherd
gnome-terminal -x ./dispatcherd -f xml/ise1.xml  &
ssh -X pcig27 'cd /home/ise/ise/trunk/dispatcherd;gnome-terminal -x ./dispatcherd -f xml/ise2.xml' &

