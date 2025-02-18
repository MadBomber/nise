#!/bin/sh

OS=`uname`
IO="" # store IP
case $OS in
   Linux) IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`;;
   FreeBSD|OpenBSD) IP=`ifconfig  | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}'` ;;
   SunOS) IP=`ifconfig -a | grep inet | grep -v '127.0.0.1' | awk '{ print $2} '` ;;
   *) IP="Unknown";;
esac

#echo "$IP"
MY_IP=""


PS3="Select the IP Address for the ISE scripts to use: "
select i in $IP; do
	if [ -n "$i" ]; then
		MY_IP=${i}
		break;
	fi
done

echo "$MY_IP"

