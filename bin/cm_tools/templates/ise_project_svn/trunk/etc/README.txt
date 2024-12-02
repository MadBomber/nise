#######################################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $<%= project_id %>_ROOT/etc
#

This directory contains files (some within sub-directories) that are
required by the <%= project_name %>.  These files are typically
configuration or resource files that must be installed in various
places within the computer's filesystem.  Each sub-directory refers
to a specific place.

It is appropriate for this README.txt file to document each of these
configruation/resource files in terms of where they go and how they are
used.

HOME/   The user's home directory.
        .roots    Contains the definitions for the standard *_ROOT
                  system environment variables used by <%= project_id %>.
                  Place the .roots file in your home directory.  Modify
                  your .bashrc file to source the .roots file.


