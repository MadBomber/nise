#! /bin/tcsh -f
##########################################################################
###
##	File:	iserelease.s
##	Desc:	prepares source files for release
##
## System Utilities used:
##	svn, gawk, fgrep, whoami, vclog, wc, tee, mktemp, cat
##
## vclog is a gem.  if you are _NOT_ using rvm it is located
## in the $HOME/.bundle/ruby/1.8/bin directory.  if you are using
## rvm then vclog should already be on the execution path.
##
## alias vclog=$HOME/.bundle/ruby/1.8/bin/vclog
#

#set echo

#############################################################
## Validate environment variables and command line parameters

if (! -d $ISE_ROOT) then

	echo "\nERROR: The ISE_ROOT environment variable is not a directory."
	exit -1

endif

if ( $#argv > 0) then

	echo "\nUsage: $0\n"
	echo "There are no command line parameters requred for this script.\n"
	echo "$0 automates the release process for ISE.\n\n"

	exit -1

endif

######################################
## Required Directories

set bin_dir             = $ISE_ROOT/bin
set cm_tools_dir        = $bin_dir/cm_tools
set regression_test_dir = $cm_tools_dir/regression_test
set output_dir          = $ISE_ROOT/output
set common_dir          = $ISE_ROOT/Common

set required_directories = "$bin_dir $cm_tools_dir $regression_test_dir $output_dir $common_dir"

set exit_state = 0

foreach dir ( $required_directories )

	if (! -d $dir) then
		set exit_state = -1
		echo "ERROR: Required directory is miissing. $dir"
	endif

end

if ( $exit_state != 0) then

	exit $exit_state

endif

##########################################
## Required Files

set runonce_sh     = $ISE_ROOT/runonce.sh
set demake_sh      = $ISE_ROOT/demake.rb
set remake_sh      = $ISE_ROOT/remake.rb
set doxygen_cfg    = $ISE_ROOT/doxygen.cfg

set build_ise_sh   = $cm_tools_dir/build_ise.sh
set iserelease_awk = $cm_tools_dir/iserelease.awk

set test_sh        = $regression_test_dir/test.sh

set iserelease_h   = $common_dir/ISERelease.h

set required_files = "$runonce_sh $demake_sh $remake_sh $build_ise_sh $doxygen_cfg $iserelease_awk $test_sh $iserelease_h"

foreach file ( $required_files )

	if (! -e $file ) then
		set exit_state = -2
		echo "ERROR: Required file is missing. $file"
	endif

end

if ( $exit_state != 0) then

	exit $exit_state

endif


#############################################
## These are generated files

set release_log    = $ISE_ROOT/Release.log

##############################################
## get the svn URL

set URL = `svn info $ISE_ROOT | gawk '"URL:" == $1 {print $2}'`

#################################################
## Create the ISERelease.h file for this reelease

echo "<Insert ChangeLog Here>" | gawk -v URL=$URL -f $iserelease_awk

set cm_tag = `fgrep "#define ISE_RELEASE" $iserelease_h | gawk '{print $4}'`

##################################################
## Update the doxygen.cfg file with release tag

set tmp_file = `mktemp`

cp $doxygen_cfg $tmp_file

gawk -v CM_TAG="$cm_tag" '$1 == "PROJECT_NUMBER" { print "PROJECT_NUMBER = " CM_TAG; next} {print $0}' $tmp_file > $doxygen_cfg

rm -fr $tmp_file

##################################################
## Check everything in, build ISE and test it

cd $ISE_ROOT

######################################################################
## Can only checkin if this is a release canidate or a developer build
## TODO: we may want to keep this a manual process for a while

#svn ci --message "Release: $cm_tag"

#############################
## Create the ChangeLog file

#if ( -x /usr/bin/svn2cl ) then
#   svn2cl -i --group-by-day --separate-daylogs --break-before-msg=2 --reparagraph --ignore-message-starting=checkpoint $ISE_ROOT --stop-on-copy
#endif

vclog changelog --id --format gnu > $ISE_ROOT/ChangeLog

#####################################
## Begine the build process

echo "Release $cm_tag Activity Log" > $release_log
echo "By: `whoami`" >> $release_log
echo "Date: `date`" >> $release_log
echo "======================================================\n" >> $release_log


cd $ISE_ROOT

# NOTE: Assuming that an svn conflict exists for Gemfile.lock
rm -fr Gemfile.lock*
bundle install >> $release_log
svn resolved Gemfile.lock


$build_ise_sh $release_log	## Passing log file name to script

################################################
## Review log for successfull build

set warning_cnt = `fgrep -i warning $release_log | wc -l` 
set error_cnt   = `fgrep -i error $release_log | wc -l`

echo "\nWarning Count: $warning_cnt"
echo   "Error Count:   $error_cnt\n"

if ($warning_cnt > 0) then

	set tmp_file = `mktemp`

	fgrep -i warning $release_log >> $tmp_file

	echo "\n\nWARNINGS were found during build process.  These should be investigated.\n\n" | tee -a $release_log
	cat $tmp_file | tee -a $release_log
	
	rm -fr $tmp_file

endif


if ($error_cnt > 0) then

	set tmp_file = `mktemp`

	fgrep -i error $release_log >> $tmp_file

	echo "\n\nERRORS were found during build process.\n\n" | tee -a $release_log
	cat $tmp_file | tee -a $release_log
	
	rm -fr $tmp_file

	exit -1

endif


#########################
## Invoke regression test

#$test_sh $release_log	### Passing release_log filename into the script

## TODO: Review regression test for errors/warnings
## TODO: Create tarball(s)

