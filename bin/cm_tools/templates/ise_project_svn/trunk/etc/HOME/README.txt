#######################################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $<%= project_id.upcase %>_ROOT/etc/HOME
#

The files in this directory should be moved to your
$HOME directory.  If files with these names already
exist in you home directory, you may want to merge the
content of these files with your existing files.

File Name           Description
=========           ===============================================

.roots              Defines the *_ROOT system environment variables
.<%= project_id.downcase %>rc<%= " "*(17-project_id.length) %>Provides for developer over-ride of system environment
                    varialbes established by the project's setup_symbols

