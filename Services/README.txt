###########################################################
###
##  File: README.txt
##  Desc: This directory $ISE_ROOT/Services provides ISE system
##        services.
#

File Name               Description

ise_job_control.rb      Provides ability to launch, terminate and startus IseJobs

      Services
      
      launch            Launches an IseJob by Name or by ID, returns the Run ID
                        Parms: IseJob(ID or Name), debug_flag, grid_flag
                        
      running?          Returns true if Run ID is running
                        Parms: Run ID
                        
      kill_run          Terminates a specific Run ID
                        Parms: Run ID


