#######################################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $<%= project_id %>_ROOT/config
#

The "config" contains configuration files in the INI format.  The
INI format was chosen because of the availability of common libraries
for various programming languages and hardware platforms that capable
of reading and writing to the format.

The directory contains at least one file: project.ini

This file contains at least one section: project

The "project" section contains project-wide configuration
information.  As a minimum it contains the project id, name
and description.  Other attributes can be added as required.

Other sections, if present, are typically model related.

See the "project.ini" file for additional information.

