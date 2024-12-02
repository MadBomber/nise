#/bin/sh

echo "No longer used!  Use  'dispatcher -h' "

exit


ISE_MAIN_CNT=`ps -ef | grep ise_main | wc -l`

if [ $ISE_MAIN_CNT -gt 1 ]; then
	killall ise_main
fi

. setup_symbols.sh
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "ISE_ROOT=$ISE_ROOT"
echo "ISE_QUEEN=$ISE_QUEEN"
#$ISE_ROOT/bin/ise_main -b -f $ISE_ROOT/etc/ISE/LogServer.conf
#sleep 3
$ISE_ROOT/bin/ise_main -b -f $ISE_ROOT/etc/ISE/dispatcherd.conf
#valgrind --tool=callgrind --log-file=$ISE_ROOT/output/dispatcher_callgrind $ISE_ROOT/bin/ise_main -b -f $ISE_ROOT/etc/ISE/dispatcherd.conf
#valgrind --leak-check=full --show-reachable=yes --num-callers=50 --log-file=$ISE_ROOT/output/dispatcher_valgrind $ISE_ROOT/bin/ise_main -b -f $ISE_ROOT/etc/ISE/dispatcherd.conf
ps -ef | grep ise_main
