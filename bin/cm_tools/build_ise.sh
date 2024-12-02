#! /bin/bash
#################################################################################
###
##	File:	build_ise.sh
##	Desc:	ensure a consistent build process
##
##	This script assumes that $cwd is $ISE_ROOT
##
##	The script has one parameter, the fully qualified name of the build log file
##
## System Utilities Used:
##	tee, mktemp, car, rm

if [ $# -lt 1 ]
then
	echo "ERROR: $0 requires 1 parameter, the build log file."
	exit -1
fi;

release_log="$1"
build_log=`mktemp`

setup_symbols_sh="./setup_symbols"
demake_sh="./demake.rb"
remake_sh="./remake.rb"

if [ -e "$setup_symbols_sh" ]
then
	source $setup_symbols_sh >> $build_log
else
	echo "ERROR: missing $setup_symbols_sh" | tee -a $build_log
	cat $build_log >> $release_log
	rm -fr $build_log
	exit -1
fi;

if [ -x  "$demake_sh" ]
then
	echo "\n\n######################################" >> $build_log
	echo     "## Removing any previous make files ##" >> $build_log
	echo     "######################################" >> $build_log
	$demake_sh --delete 2>&1 | tee -a $build_log
else
	echo "ERROR: missing $demake_sh" | tee -a $build_log
	cat $build_log >> $release_log
	rm -fr $build_log
	exit -2
fi;

if [ -x "$remake_sh" ]
then
	echo "\n\n############################" >> $build_log
	echo     "## Creating GNUmakefiiles ##" | tee -a $build_log
	echo     "############################\n\n" >> $build_log
	$remake_sh 2>&1 | tee -a $build_log
else
	echo "ERROR: missing $remake_sh" | tee -a $build_log
	cat $build_log >> $release_log
	rm -fr $build_log
	exit -2
fi;

echo "\n\n############################################" >> $build_log
echo     "## Cleaning out leftovers from last build ##" | tee -a $build_log
echo     "############################################\n\n" >> $build_log

make realclean >> $build_log

echo "\n\n##################" >> $build_log
echo     "## building ISE ##" | tee -a $build_log
echo     "##################\n\n" >> $build_log

make 2>&1 | cat - >> $build_log

echo "\n\n####################" >> $build_log
echo     "## build finished ##" | tee -a $build_log
echo     "####################\n" >> $build_log

cat $build_log >> $release_log

rm -fr $build_log
