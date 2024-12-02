These are files used in building new versions of ACE.
Read the old way of building ACE to understand where these go.

Jack Lavender
5/15/2008

=========================================
How to build ACE

get the ACE source code

  cd $HOME/sandbox
  svn co svn://svn.dre.vanderbilt.edu/DOC/Middleware/sets-anon/ACE
  cd ACE/ACE_wrappers
  export ACE_ROOT=`pwd`

set up pointers to lib directory for build

  export LD_LIBRARY_PATH=$ACE_ROOT/lib:$LD_LIBRARY_PATH

copy ACE config files from $ISE_ROOT/ACE

  cp $ISE_ROOT/ACE/ace/config.h $ACE_ROOT/ace
  cp $ISE_ROOT/ACE/include/makeinclude/platform_macros.GNU $ACE_ROOT/include/makeinclude

generate the make files

  cd $ACE_ROOT
  ./bin/mwc.pl -type gnuace ACE.mwc

now compile the libraries

  make

run the ACE regression tests

  ./tests/run_test.pl


