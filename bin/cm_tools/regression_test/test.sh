#!/bin/bash
###########################################################################
###
##	File:	test.sh
##	Desc:	controls the regression test
##
##	Expects to be called with 1 parameters, the test_log filename
##
## System utilities used:
##	fgrep, wc
#
# TODO: complete the stubs

########################################################
## Validate the command line parameters

if [ $# == 1 ]
then
	test_log="$1"
else
	echo "\n\nERROR: $0 expects 1 parameter, the test log file name."
	exit -1
fi;

####################################
## TODO: verify environment varibles

output_dir=$ISE_ROOT/output

passed_status=0			## Exit return code for PASS
failed_status=1			## Exit return code for FAIL
exit_status=$passed_status	## Assume the regression tests pass

compare_expected_results_s=$output_dir/compare_expected_results.s

echo "\n\n###############################" >> $test_log
echo     "## Begin Regression Tests ##" | tee -a $test_log
echo     "############################\n" >> $test_log

echo "Dummy Stub" | tee -a $test_log

## TODO: execute runjob three times

echo "runjob ... wait 60s ... get directory from ISE_TEST"
#sleep 60s
job1_output_dir=$ISE_TEST

echo "runjob ... wait 60s ... get directory from ISE_TEST"
#sleep 60s
job2_output_dir=$ISE_TEST

echo "runjob ... wait 60s ... get directory from ISE_TEST"
#sleep 60s
job3_output_dir=$ISE_TEST


## TODO: wait for all three jobs to complete

echo "wait for each job to complete; how do I know?"
echo "could watch the VAT1.log file for each job looking for the last line."

## TODO: compare each run to Expected_Results

echo "Job1 Regression Test Results" | tee -a $test_log
#$compare_expected_results_s $job1_output_dir >> $test_log

echo "Job2 Regression Test Results" | tee -a $test_log
#$compare_expected_results_s $job2_output_dir >> $test_log

echo "Job3 Regression Test Results" | tee -a $test_log
#$compare_expected_results_s $job3_output_dir >> $test_log

#runjob -t	## clean up from tests

###########################################################
## Review test log for failures

fail_cnt=`fgrep -i fail $test_log | wc -l`

if [ $fail_cnt -gt 0 ]
then
	exit_status=$failed_status
fi;

echo "\n\n#############################" >> $test_log
echo     "## End of Regression Tests ##" | tee -a $test_log
echo     "#############################\n" >> $test_log



exit $exit_status
