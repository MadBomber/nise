#######################################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $<%= project_id %>_ROOT/Scenarios
#

The Scenarios directory contains the IseScenario scripts.  These
scripts are used by the generic scenario_driver, a component of
the ISE project.  These scenarios can be used to controll the timing
of various events that occure within the <%= project_name %> project.

For example and IseScenario could insert specific IseMessages into
an IseJob at given times or intervals.

To make use of IseScenario scripts the scenario_drive must be part
of your IseJob.



