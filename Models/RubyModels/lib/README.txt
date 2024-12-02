###############################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $ISE_ROOT/Models/RubyModels/lib
#

This directory contains common library files that are 'require'd by
several/many of the ruby-based tools within the ISE project.  In addition
those simulation projects that use ISE have contributed common libraries
to be reused by other projects.

The file naming convention is to use CamelCase.rb for a file that defines
a class CamelCase or module CamelCase.  For library files that bundle various
utility methods, code, or modifications to system classes the
snake_case_file_name.rb is appropriate.

The majority of the files in this directory were previously located in the
IsePortal repository's lib directory.  They were moved to this repository to
facilitate code reuse.  As a concequence of the move all subversion log history
prior to April 21, 2010 has been lost.  This history, however, can still
be accessed from the IsePortal repository.

