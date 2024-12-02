#! /bin/tcsh
################################################################################
###
##	File:	compare_expected_results.s
##	Desc:	runs diff on all files found in the expected results directory
##		against those found in the run directory
##
##	Parameters:
##		run_dir
##
##	System Utilities Used:
##		diff, wc, gawk, ident, rm


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

echo "\nRegression Testing For Release"
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

	diff $run_dir/$base_filename $filename > $run_dir/${base_filename}.diff

end

echo "\nThe following diff files were created:\n"
echo " Lines Filename"
echo "------ ----------------------------"
wc -l $run_dir/*.diff

set pass_fail_str = "`wc -l $run_dir/*.diff`"

set total_line = $#pass_fail_str

set line_cnt = `echo $pass_fail_str[$total_line] | gawk '{print $1}'`

if ( $line_cnt > 0 ) then

	echo "\nFAILED:  Review each diff file before validating this release."
	set exit_status = -2

else

	echo "\nPASSED."

endif

echo "\n"

exit $exit_status

#######################################################################
Usage:

echo "\nUsage:\t$0 run_dir\n\n"
echo "\t Where run_dir is a directory that contains the output files"
echo "\n"

exit -1



