#! /bin/tcsh -f
#####################################################################################
###
##	File:	run_tests.s
##	Desc:	Executes the unit test programs and compares output to expected output
#

set fail_cnt = 0
set pass_cnt = 0

foreach unit_test (*_UnitTest_*)
	if(! -x $unit_test) continue
	echo -n "Executing $unit_test ..."
	./$unit_test > ${unit_test}.txt
	diff ${unit_test}.txt Expected_Results/${unit_test}.txt > ${unit_test}.diff
	set results = `wc -l ${unit_test}.diff`
	if($results[1] > 0) then
		echo "\tFAILED <<<<===---"
		cat ${unit_test}.diff
		@ fail_cnt += 1
	else
		echo "\tpassed"
		@ pass_cnt += 1
	endif
end

echo "\n\n"
echo "Failed Tests: $fail_cnt"
echo "Passed Tests: $pass_cnt"

echo "\nDone."
