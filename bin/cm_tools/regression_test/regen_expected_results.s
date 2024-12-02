#! /bin/tcsh
################################################################################
###
##	File:	regen_expected_results.s
##	Desc:	overwrites the data files in the expected results directory with the files from
##		a run output directory.
##
##	Parameters:
##		run_dir
##
##	System Utilities Used:
##		ident, cp

## TODO: reorient this script to run from bin/cm_tools/regression_test

set whereami = `basename $cwd`

if ( $whereami != "output" ) then

	echo "\nERROR: This script must run from the output directory."
	goto Usage

endif

if ( 1 != $#argv ) then

	goto Usage

endif

if (! -d $1) then

	echo "\nERROR: Parameter is not a directory. $1\n" 
	goto Usage

endif

##################################################################
## Params have been verified

echo "\nRegenerating Expected Results Files"
ident ../Common/ISERelease.h

set exit_status       = 0
set results_dir       = "Expected_Results"
set run_dir           = $1

rm -f $run_dir/*.diff

foreach filename ( $results_dir/* )

	if (-d $filename ) then
		continue
	endif

	set base_filename = `basename $filename`

	if (! -e $run_dir/$base_filename) then

		echo "\nERROR: File not found.  Looking for $run_dir/$base_filename ..."
		set exit_status = -1
		continue

	endif

	cp -i $run_dir/$base_filename $filename

end

exit $exit_status

#######################################################################
Usage:

echo "\nUsage:\t$0 run_dir\n\n"
echo "\t Where run_dir is a directory that contains the output files"
echo "\n"

exit -1



