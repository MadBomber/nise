#########################################################################
###
##  IseRun: Encapsulates all ofthe classes and methods needed to execute
##          an IseJob.  An IseJob can be executed either on the localhost or
##          it can be submitted to the IseCluster.
##
##  The primary classes used from IseDatabase are:
##    Job, JobConfig, Model, RunPeer, Run
##
##
## TODO: Add an erb layout to make the pick_a_job list look pretty
## TODO: Add ISE_RUN_INPUT;  make default ISE_RUN + "input"  (consider use of Job.name)
## TODO: Add ISE_RUN_OUTPUT; make default ISE_RUN + "output" (consider use of Job.name)
## TODO: Look at runtime configuration file (YAML) for an IseJob to over-ride IseDatabase JobConfig
##


require 'IseDatabase'           ## Access to the main tables in the IseDatabase
require 'highline/import'       ## GEM: high-level line oriented console interface
require 'uuidtools'             ## GEM: various tools for creating globally unique identifiers

if $ISE_GOOD.nil?                       ## indicates that the environment has not been established
  establish_and_validate_environment    ## Ensures that the ISE environment is workable; basically
  ## that the setup_symbols script has been run

  unless $ISE_GOOD
    puts "Please correct the problems noted."
    puts "... terminating."
    exit
  end
end

# Encapsulate the methods used to setup and execute an IseJob.
# Uses a simple state machine with three states:
#
#     initialize -> setup -> execute -> setup
#
# this prevents the setup and execute methods from being called
# out of turn.
#
# There are four ways to specify which IseJob to run:
#
#     a = IseRun.new                ## Choose the IseJob to run from a menu
#     a = IseRun.new(3)             ## Use IseJob.id   == 3 to run
#     a = IseRun.new("samson_3on3") ## Use IseJob.name =="samson_3on3" to run
# and
#     my_job = Job.find_xxx( conditions )  ## for example, my_job = Job.find(:first)
#     a = IseRun.new(my_job)
#
# To submit the same IseJob multiple times
# you can do something like this:
#
#     99.times do
#       a.setup     ## Creates a new runtime configuration
#       a.execute   ## Submits the IseJob to localhost or to the grid
#     end
#

class IseRun

  @@me = nil

  # The IseJob selected by the user to run.  It contains the row from
  # the jobs table in the Delilah database.

  attr_accessor :job

  # The run record from the runs table in the Delilah database

  attr_accessor :run

  # The user record from the users table in the Delilah database

  attr_accessor :user

  # Instaniate an IseRun

  def initialize (my_job = nil)

    @state = "initialize"

    validate_ise_default_job
    validate_ise_cluster

    valid_class = ["String", "Fixnum", "Job"]
    unless my_job.nil? || valid_class.include?(my_job.class.to_s)
      ERROR(["Unexpected parameter class.",
        "Valid classes are: #{valid_class.inspect}",
        "    Bad class was: #{my_job.class}",
        "    Bad value was: #{my_job.inspect}"
      ])
      return nil    ## take early retirement
    end

    @job  = nil      ## The record from the jobs table in Delilah
    @run  = nil      ## The record from the runs table in Delilah
    @user = nil      ## The record from the users table in Delilah

    @user = User.find_by_login($USER)

    unless @user
      @user = User.new
      @user.login = $USER
      @user.save
    end


    if my_job.nil?

      if $ISE_DEFAULT_JOB   ## Assume if set, its a valid IseJob, can be either an id or a name
        @job = $ISE_DEFAULT_JOB
      else

        # Present user with a pick list of IseJobs in the IseDatabase
        my_job = pick_a_job
        @job = Job.find(my_job) if my_job > 0

      end
    else
      begin
        @job = case my_job.class.to_s
        when "String" then Job.find_by_name(my_job)
        when "Fixnum" then Job.find(my_job)
        when "Job"    then my_job
        else nil
        end ## end of case
      rescue
        @job = nil
      end
    end   ## end of if/else

    # SMELL: Violates 1 method 1 function
    unless User.find_by_login(ENV["USER"])
      a_new_user = User.new
      a_new_user.login = ENV["USER"]
      a_new_user.save
    end

    if @job
      @state = "setup"
    end

  end     ## end of initialize


  ##############################################################################
  # Do everything necessary to run an IseJob up to the point of actual execution

  def setup

    # Create a new run record in the IseDatabase

    if @state == "setup"     ## Protect against a multiple call

      @run = Run.new

      @run.job_id              = @job.id
      @run.user_id             = User.find_by_login($USER).id
      @run.status              = 0  ## Not ready to execute, in prep phase
      @run.notification_method = 0  ## TODO: How does the user want to be notified when job completes?
      @run.guid                = UUIDTools::UUID.random_create.to_s

      puts "The GUID for this run is: #{@run.guid}" if $VERBOSE

      # Setup the IseJob-level input/output directory over-rides
      # Level-one IseJob designer said these are the defaults:

      @run.input_dir           = @job.default_input_dir
      @run.output_dir          = @job.default_output_dir

      # Level-two $ISE_RUN is set

      if $ISE_RUN
        @run.input_dir         = ($ISE_RUN + "input").to_s
        @run.output_dir        = ($ISE_RUN + "output").to_s
      end

      # Level-three $ISE_RUN_INPUT and/or $ISE_RUN_OUTPUT is set

      @run.input_dir  = $ISE_RUN_INPUT.to_s  if $ISE_RUN_INPUT
      @run.output_dir = $ISE_RUN_OUTPUT.to_s if $ISE_RUN_OUTPUT


      # Create the output directory for the IseRun using the guid

      # SMELL: Using a GUID in a user visible way sucks; need something more meaningful to the user.
      # JKL Note: I agree that the GUID is ugly and meaningless, but the important part is uniquenss.

      output_dir = Pathname.new(@run.output_dir) + @run.guid    ## SMELL: rather see a user meaningful name

      @run.output_dir        = output_dir.to_s

      begin
        output_dir.mkdir
      rescue StandardError => error_msg
        ERROR(["Unable to create the output directory for this run.",
          "Output Directory: #{output_dir.to_s}",
        "#{error_msg}"])
        exit
      end


      # Save the run record.  If any errors happen after this, the
      # record will have to be deleted.

      @run.save


      # Create the GUID database for IseRun database output

      #begin
        IseDatabase.create_guid_database(@run.guid)
      #rescue Exception => e
      #  ERROR(["Unhandled internal error associated with creating the guid database.", e])
      #  exit
      #end


      @state = "execute"
    else
      nil
    end ## end of if/else state guard
  end   ## end of setup


  ########################################################
  # submit an IseJob to the IseCluster or to the localhost

  def execute

    if @state == "execute"

      job_commands = build_commands

      job_commands.each do |the_cmd|

        puts the_cmd if $VERBOSE

        system the_cmd  ## launch the application
        #sleep 1         ## take a 1 second nap between launches to spread load on the IseDatabase

      end  ## end of job_commands.each do |the_cmd|

      @state = "setup"

    else
      nil
    end ## end of if/else state guard
  end   ## end of execute


  ########################################################
  # submit an IseJob to the IseCluster or to the localhost

  def dryrun

    job_commands = build_commands

    job_commands.each do |the_cmd|

      puts the_cmd  ## launch the application

    end  ## end of job_commands.each do |the_cmd|

    return nil

  end   ## end of execute


  #################################################
  ## build_commands creates an array of commands to
  ## be submitted for execution

  def build_commands

    @run = Run.find(@run.id) if @run    ## refresh the run record if it exists; this gets any mods made to @run.debug_flags

    run_commands = []

    # Build the execution stack from the run_peers table for this run

    job_config = JobConfig.find_all_by_job_id(@job.id)
    puts job_config.columnized if $DEBUG

    # Submit IseJob to the localhost or to the IseCluser

    run_dir   = $ISE_RUN + "bin"
    base_cmd  = $GRID ? "qsub  -q '*@#{ENV["ISE_GRID"]}' "  + run_dir.to_s + "/" : ""
    
    cpp_peer  = "peerd"
    ruby_peer = 'peerrb'
    java_peer = 'peerj'
    
    cmd_suffix = $GRID ? ".sge" : ""

    ise_run_bin = $ISE_RUN + "bin"

    # FIXME: The $DEBUG global is not set; but, it was on the command line.

    console_switch = ($DEBUG_MDL) ? '' : '/B'

    #    puts "================================================================"
    #    puts "== $DEBUG: #{$DEBUG}     $DEBUG_MDL: #{$DEBUG_MDL}"
    #    puts "================================================================"

    DEBUG(["$DEBUG: #{$DEBUG}",
      "$DEBUG_MDL: #{$DEBUG_MDL}",
    "console_switch: #{console_switch}"])

    base_cmd_mswin32 = "start \"TITLE\" #{console_switch} peerd"

    job_config.each do | jc |

      the_cmd            = base_cmd.dup     ## ensure that the same base_cmd is used each tome through the loop
      model              = jc.model


      the_cmd  = base_cmd
      
      
      case model.platform.name.downcase
        when 'ruby' then
          the_cmd += ruby_peer
          it_is_a_ruby_model = true
        when 'any' then         # NOTE: Legacy platform when Ruby was the only non compiled language supported
          the_cmd += ruby_peer
          it_is_a_ruby_model = true
        when 'java' then
          the_cmd += "#{java_peer} "
          it_is_a_java_model = true
        else
          the_cmd += cpp_peer
      end
      
      
      the_cmd += cmd_suffix
      
      
      # NOTE: mswin32 as a platform signals a windoze executable
      if model.platform.name.include?('mswin32')
        the_cmd = base_cmd_mswin32
        mswin32 = true
      else
        mswin32 = false
      end


      the_cmd += " -j#{@run.id}"                              ## The ID for this specific runjob
      the_cmd += " -k#{model.name}"                           ## The name of this model

      the_cmd["TITLE"] = model.name if mswin32      ## Puts the model's name into the window title on mswin32

      the_cmd += " -l#{model.dll}"
      the_cmd += " -u#{jc.model_instance}"
      
      
      case model.router.downcase.to_sym    # TODO: Might want to make router a list
        when :amqp then
          router_cmd = " --amqp"
        when :xmpp then                     # TODO: Create an XMPP IseRouter
          router_cmd = " --xmpp"
        when :dispatcher then
          router_cmd = " --dispatcher"
        when :both then                     # NOTE: 'both' has no meaning with 3+ IseRouters
          router_cmd = " --amqp --dispatcher"
        else
          router_cmd = ""                   # NOTE: Supports legacy systems that can not handle --dispatcher
      end
      
      the_cmd += router_cmd
      

      # NOTE:  port numbers are different between Windows and Linux models
      #        windows architecture is to not have a local IseDispatcher but
      #        rather an $ISE_GATEWAY node contains the IseDispatcher


      # FIXME: The ISE_GATEWAY concept was created because the BOOST library's type_of macro used by the IseDispatcher does not work on MS Windows

      if model.platform.name.include?('mswin32')
        the_cmd += " -c8003 -h #{$ISE_GATEWAY}"  if router_cmd.include?('dispatcher')
        ## 8003 is the port defined as the windows channel
        ## $ISE_GATEWAY is an IseNode running an IseDispatcher
        ## that is dedicated to the windows junk
      else
        ## FIXME: hardcoded port number
        the_cmd += " -c8001"  if router_cmd.include?('dispatcher')
      end

      ##### the_cmd += " -c#{$ISE_PORT}"              ## $ISE_PORT is the default port


      the_cmd += " -O"                                         ## What does this parameter mean ?

      the_cmd += " -s" if $LOGSTATE                                     ## switch for the logging of an IseModel's state
      the_cmd += insert_overrides_as_necessary(jc, it_is_a_ruby_model)  ## inserts the -d options and model's params as necessary


      the_cmd += " &" unless mswin32                           ## submit the job into the background

      run_commands += [the_cmd]                                ## Add this command to the list of commands
    end

    return run_commands

  end ## end of build_commands


  ##############################################################
  ## insert appropriate debug flags onto command line parameters
  ## with over-rides as necessary
  ##
  ## TODO: The concept of the run model over-rides has never been used.  It needs to
  ##       deprecated and removed from ISE.  Its problem stems from the lack of
  ##       a GUI interface to ISE.  Even with a good GUI its likely that no one will
  ##       make use of this capability.

  def insert_overrides_as_necessary(a_jc, ruby_model=false)

    ## in this method the 'df_'  prefix refers to debug_flags
    ##                    'clp_' prefix refers to cmd_line_param

    df_str  = ''
    clp_str = a_jc.cmd_line_param.nil? ? '' : "#{a_jc.cmd_line_param}"

    # Check the generic run_id == 0 && all users && all instances
    run_id   = 0
    user_id  = 0
    model_id = a_jc.model_id
    instance = 0
    begin
      rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
      df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
      clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
    rescue
    end


    # Check the generic run_id == 0 && this users && all instances
    run_id   = 0
    user_id  = @user.id
    model_id = a_jc.model_id
    instance = 0
    begin
      rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
      df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
      clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
    rescue
    end


    # Check the generic run_id == 0 && all users && this specific instances
    run_id   = 0
    user_id  = 0
    model_id = a_jc.model_id
    instance = a_jc.model_instance
    begin
      rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
      df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
      clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
    rescue
    end


    # Check the generic run_id == 0 && this user && this specific instances
    run_id   = 0
    user_id  = @user.id
    model_id = a_jc.model_id
    instance = a_jc.model_instance
    begin
      rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
      df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
      clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
    rescue
    end


    # Check the specific run_id == @run.id
    unless @run.nil?

      # Check the specific run_id && all users && all instances
      run_id   = @run.id
      user_id  = 0
      model_id = a_jc.model_id
      instance = 0
      begin
        rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
        df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
        clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
      rescue
      end

      # Check the specific run_id && this user && all instances
      run_id   = @run.id
      user_id  = @user.id
      model_id = a_jc.model_id
      instance = 0
      begin
        rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
        df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
        clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
      rescue
      end

      # Check the specific run_id && all users && this specific instances
      run_id   = @run.id
      user_id  = 0
      model_id = a_jc.model_id
      instance = a_jc.model_instance
      begin
        rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
        df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
        clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
      rescue
      end

      # Check the specific run_id && this user && this specific instances
      run_id   = @run.id
      user_id  = @user.id
      model_id = a_jc.model_id
      instance = a_jc.model_instance
      begin
        rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
        df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
        clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
      rescue
      end

    end ## end of unless @run.nil?


    # Check the any run_id && any user && any model && any instances
    run_id   = 0
    user_id  = 0
    model_id = 0
    instance = 0
    begin
      rmo     = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
      df_str  = rmo.debug_flags    if rmo && rmo.debug_flags.length > 0
      clp_str = rmo.cmd_line_param if rmo && rmo.cmd_line_param.length > 0
    rescue
    end

    unless @run.nil?

      # is there a job-level run-time over-ride for all models for this run id?

      df_str = @run.debug_flags if @run.debug_flags.length > 0

    end ## end of unless @run.nil?


    # The system environment variables over-rides everything
    # df_str = $DEBUG_FLAGS if $DEBUG_FLAGS

    df_str = $debug_flags if $DEBUG_MDL     ## this stuff comes from ise.rb


    df_str  = " -d"  + df_str  if df_str.length > 0

    clp_sep = ruby_model ? '-#' : ''

    clp_str = " #{clp_sep} #{clp_str}" if clp_str.length > 0

    clp_str = " --verbose #{clp_str}" if $VERBOSE

    return df_str + clp_str

  end ## insert_overrides_as_necessary


  ###################
  ## Class Methods ##
  ###################



  ######################################################################
  ## Delete a run, its associated peers and the associated GUID database
  ##
  ## Delete Sequence:
  ##  1. RunSubscriber
  ##  2. RunMessages
  ##  3. RunPeer
  ##  4. RunModel
  ##  5. GuidDatabase
  ##  6. Output directory
  ##  7. Run
  ##
  ##  TODO: Add some error checking to delete_a_run
  #

  def self.delete(my_run, force=false)

    @@me = User.get_me if @@me.nil?

    my_run = Run.find(my_run) unless 'Run' == my_run.class.to_s

    unless my_run.user_id == @@me.id
      return
    end

    ## If currently running, don't delete it!
    ## unless the user forces you to delete
    unless force
      if my_run.status != 0 then
        puts "Cannot removed run #{my_run.id}"
        return
      end
    end

    ## If ouput does not exist, don't!
    ## NOTE:  output_dir is stored as an absolute path
    ## SMELL: This procedure does not take into account a cross-platform file system.
    unless Pathname.new(my_run.output_dir).exist?
      if RUBY_PLATFORM.include?("mswin32")
        if my_run.output_dir[0,1] == '/'
          puts "Cannot removed run #{my_run.id}"
          return
        end
      else
        unless my_run.output_dir[0,1] == '/'
          puts "Cannot removed run #{my_run.id}"
          return
        end
      end
    end

    ## 1. delete all run_subscribers associated with this run
    my_run_messages = RunMessage.find_all_by_run_id(my_run.id)
    unless my_run_messages.nil?
      my_run_messages.each do |mrm|
        RunSubscriber.delete_all "run_message_id = #{mrm['id']}"
      end
    end

    ## 2. delete all run_messages associated with this run
    RunMessage.delete_all "run_id = #{my_run.id}"

    ## 3. delete all run_peers associated with this run
    my_run_models = RunModel.find_all_by_run_id(my_run.id)
    unless my_run_models.nil?
      my_run_models.each do |mrm|
        RunPeer.delete(mrm.run_peer_id)
      end
    end
    
    ## 3a. delete all run_externals associated with this run
    
    RunExternal.delete_all "run_id = #{my_run.id}"
    

    ## 4. delete all run_models associated with this run
    RunModel.delete_all "run_id = #{my_run.id}"

    ##  5. delete the guid database associated with this run
    IseDatabase.drop_guid_database(my_run.guid)

    ## 6. delete the output directory associated with this run
    begin
      Pathname.new(my_run.output_dir).rmtree
    rescue SystemCallError => e
      $stderr.puts e.message
    end

    ## 7. delete this run record
    Run.delete(my_run.id)

  end

  ####################################################################
  # CAUTION: only pull the trigger when you know what you are shooting
  def self.delete_all(force=false)

    all_runs = Run.find(:all)

    all_runs.each do |a_run|

      self.delete(a_run, force)

    end

  end


  #################################
  ## Private / Protected Methods ##
  #################################

  ############################################################
  # Give user a choice of which IseJob to run

  # SMELL: pick_a_job should be somewhere other than IseRun

  private
  def pick_a_job

    which_job = 0     ## This will be the return symbol, a Job.id
    all_jobs  = Job.find(:all)

    if all_jobs.nil?
      ERROR(["There are no IseJobs registered in the IseDatabase."])
    else
      puts '\n'

      answer = choose do |menu|
        menu.select_by = :name
        menu.header    = "The following IseJobs are currently registered in the IseDatabase"
        menu.prompt    = "Which IseJob do you want to execute?"

        all_jobs.each_index do |x|
          menu.choice(all_jobs[x].id.to_s + ") " +all_jobs[x].name + ": " + all_jobs[x].description) do
            which_job = all_jobs[x].id
          end
        end

        menu.choice "Quit!"
      end

      if answer == "Quit!"
        DEBUG(["User chose to quit."])
      end

    end

    return which_job

  end ## pick_a_job

end    ## class IseRun





