###############################################################################
# IseJob:
# Ecapsulates the necessary and sufficient attributes that comprise an IseJob
# for registration within the IseDatabase.

require 'IseJCL_Utilities'  ## support utilities

require 'IseModel'

class IseJob
  include IseRouter
  
  # Unique identifier for the job in the IseDatabase
  attr_accessor   :id

  # Short descriptive name for the job
  attr_accessor   :name

  # Single line description of the job
  attr_accessor   :desc

  # An array of all of the modesl that comprise the job
  attr_accessor :models

  # A default base path to pre-pend for job-related relative paths
  attr_reader :basepath

  # A default path to the input directory for this IseJob
  attr_reader :input_dir

  # A default base to the output directory for this IseJob
  attr_reader :output_dir


  #####################################################################
  #Constructor Example
  #
  #PAR_1on1 =
  #IseJob.new(                 # The required parameters must be presented in the following order
  #   "PAR_1on1",              # The name of the job; should be same as name on left side of =
  #   "generic flying target"  # A short single line description of the IseJob
  #)


  def initialize(name, desc)
    @id        = 0
    @name      = name
    @desc      = desc
    @models    = []
    @basepath  = Pathname.new("")
    @router    = DEFAULT_ROUTER

    quick_check

    @input_dir  = Pathname.new("input") + name
    @output_dir = Pathname.new("output") + name

    puts "IseJob #{@name} initialized" if $DEBUG

  end


  ######################################################################
  ## Used in an IseJCL definition to initialize an IseJob instance
  def self.init(job_name, job_desc="An IseJob")
    if Job.find_by_name(job_name)
      ## replace is the same thing as a delete followed by a new
      peerrb_test = IseJob.replace(   # Note use of parens to enclose the parameters
          job_name)                   # Some short meaningful name
    else
      peerrb_test = IseJob.new(       # Note use of parens to encolse the parameters
          job_name,                   # Some short meaningful name
          job_desc)       # Single line description,
    end
  end ## end of def self.init(job_name, job_desc="An IseJob")


  #####################################################################
  ## Do a quick check of the name and desc

  def quick_check

    is_good = true

    if @name.empty? then
      @name = 'Test'
      WARNING(["Job name is blank.  Using '#{@name}' as default."])
    end

    if @desc.empty? then
      @name = 'Test description.'
      WARNING(["Job desc (description) is blank.  Using '#{@desc}' as default."])
    end
     
    unless valid_router?
      ERROR([
          "The specified router #{@router} is not supported.",
          "Supported message routers are: #{VALID_ROUTERS.join(', ')}"
      ])
      is_good = false
    end


    return is_good

  end

  #####################################################################
  ## Replace an existing IseJob in the database

  def self.replace(name, desc=nil)

    new_ise_job = self.new(name, "unknown")     ## establish an instance of the IseJob class

    begin

      # lookup this IseJob's name in the IseDatabase
      job = Job.find(:first, :conditions => ["Name = :name", {:name => new_ise_job.name} ])

      new_ise_job.id   = job.id
      new_ise_job.desc = desc.nil? ? job.description : desc  ## allows replacing a job using a different description

    rescue
      ERROR([   "Requested IseJob, #{new_ise_job.name}, does not exist.",
      "Replacement is not possible.  Try 'IseJob.new( ... )'"])
      new_ise_job = nil
    end

    # TODO: Need to build a complete IseJob object (includes job_configs and models) from the IseDatabase
    # TODO: or Rethink the relationship between IseJob and Job class, etc.

    return new_ise_job

  end


  #####################################################################
  ## Delete an existing IseJob from the IseDatabase

  def self.delete(which_job)   ## which_job can be an id, a name or an IseJob

    parm_type = which_job.class.to_s

    if     parm_type == "Fixnum"
      begin
        a_job = Job.find(which_job)
      rescue
        a_job = nil
      end
    elsif  parm_type == "String"
      a_job = Job.find_by_name(which_job)
    elsif  parm_type == "IseJob"
      which_job = which_job.name
      a_job = Job.find_by_name(which_job)
    else
      ERROR(["The parameter is of an unsupported class: #{parm_type}",
             "Please use a job's id, name or an IseJob object."])
      return nil
    end

    unless a_job
      ERROR(["Job #{which_job} was not found in the IseDatabase."])
      return nil
    end

    # found an existing job in the IseDatabase

    old_job_id   = a_job.id
    old_job_name = a_job.name
    old_job_desc = a_job.description

    # delete the job

    Job.delete(old_job_id)

    # delete the job_config

    JobConfig.delete_all "job_id = #{old_job_id}"

    # TODO: delete the the stuff associated with each run of this job

    # delete all runs fpr this job

    Run.delete_all "job_id = #{old_job_id}"

    INFO(["Deleted Job: #{old_job_name} (id: #{old_job_id})",
          "       Desc: #{old_job_desc}"])

    return nil
  end

  #####################################################################
  # Add existing IseModel(s) to an IseJob

  def add(model)  ## can be an array of IseModels or just one IseModel

    [model].flatten.each do |a_model|       ## ensure that parameter is an array
      if a_model.class.name == 'IseModel'
        # puts "IseJob #{@name} adding IseModel " + a_model.name
        # Prevent duplicate IseModel objects;
        # forces use of :count attribute over adding
        # the same object multiple times...
        if @models.index(a_model)
          ERROR(["IseModel #{a_model.name} already part of IseJob #{@name}"])
        else
          @models += [a_model]    # This ensures a flat array of only IseModel objects
        end
      else
        ERROR(["Attempting to add something that is not an IseModel to an IseJob.",
        "Class of thing: " + a_model.class.name + " thing: " + a_model])
      end

    end

    @models.sort{|a,b| a.name <=> b.name}   # keep the models sorted by name

  end

  #####################################################################
  # Remove IseModels from an IseJob

  def remove(model)   ## an array of IseModels or just one IseModel

    [model].flatten.each do |a_model|
      if a_model.class.name == "IseModel"
        @models.delete(a_model)
      else
        ERROR(["Attempting to remove something that is not an IseModel from an IseJob.",
        "Class of thing: " + a_model.class.name + " thing: " + a_model])
      end
    end

  end

  #####################################################################
  # Convert the major attributes of an IseJob to a string.

  def to_s    # Convert the job to a string for display
  
    a_str  = "Job:        #{@name}\n"
    a_str << "Desc:       #{@desc}\n"
    a_str << "Msg Router: #{@router}\n"
    a_str << "Basepath:   #{@basepath}\n"
    a_str << "Input Dir:  #{@input_dir}\n"
    a_str << "Output Dur: #{@output_dir}"
    
    return a_str
  end


  #####################################################################
  # Print to STDOUT the major attributes of an IseJob an all IseModel(s) that
  # are associated with the job.

  def show   # show the job's configuration
    puts self
    puts
    puts "#{@models.flatten.length} Associated Models:"
    @models.each do |my_model|
      my_model.show
    end
  end

  #####################################################################
  # Accept and validate as necessary the optional basepath for an IseJob.

  def basepath=(a_path)
    if a_path.nil?
      ERROR(["An IseJob basepath was assigned a NIL parameter"])
    else
    
      @basepath = Pathname.new(a_path)
      unless @basepath.exist? and @basepath.directory?
        ERROR(["'basepath' when specified must be an existing directory."])
      end
      unless @basepath.absolute?
        ERROR(["An IseJob basepath, if specified must be an absolute path to an existing directory."])
      end
    
    end
  end


  #####################################################################
  # Accept and validate as necessary the optional default input directory
  # for an IseJob.

  def input_dir=(a_path)
    @input_dir = apply_basepath_to(Pathname.new(a_path))
  end

  #####################################################################
  # Accept and validate as necessary the optional default output directory
  # for an IseJob.

  def output_dir=(a_path)
    @output_dir = apply_basepath_to(Pathname.new(a_path))
  end

  # TODO: make apply_basepath_to private
  def apply_basepath_to (a_path)

    if @basepath.to_s.length > 0
      new_path = a_path.relative? ? @basepath + a_path : a_path
    else
      new_path = a_path
    end

    unless new_path.directory?
      WARNING(["Path specified is not a valid directory.",
               "Path: #{new_path}"])
    end

    return new_path

  end

  #####################################################################
  # Create a deep copy of a job

  def clone
    new_job = super
    new_job.id = 0
    pp new_job
    return new_job
  end

  #####################################################################
  # Check / Validate all aspects of an IseJob and it's associated models extending the
  # optional default basepath(s) to all relative paths.

  def check() # Check the IseJob for validity
    is_good = true  # Assume everything is good until proven otherwise

    puts "Checking IseJob: #{@name} ..." if $DEBUG

    is_good = is_good && self.quick_check

    if @id == 0
      a_job = Job.find(:first, :conditions => ["Name = :name", {:name => @name} ])

      unless a_job.nil?
        ERROR([ "Attempting to redefine an existing IseJob.",
                "Use either:",
                "\tIseJob.delete(\"#{@name}\")",
                "\tIseJob.new ...",
                "or",
                "\tIseJob.replace(\"#{@name}\")"])
        is_good = false
      end

    end

    # Prepend the IseJob's absolute @basepath to the IseModel's relative basepath
    unless @basepath.to_s.length == 0           # apply to all models in the job, if needed
      @input_dir  = apply_basepath_to(@input_dir)
      @output_dir = apply_basepath_to(@output_dir)
      @models.each do |model|
        if model.basepath.relative? then
          model.basepath = @basepath + model.basepath
        end
      end       ## end of @models.each do |model| loop
    end         ## end of unless @basepath.to_s.length == 0 logical test

    @models.each do |model|

      # Decide to use either the IseModel's basepath or the IseJob's default input and output directories

      model.inputs.each_index do |x|
        unless model.inputs[x].class.to_s == "Pathname"
          if model.inputs[x].length > 0
            model.inputs[x] = Pathname.new(model.inputs[x])
          end
        end   ## unless model.inputs[x].class.to_s == "Pathname"

        unless model.inputs[x].class.to_s != "Pathname"
          if model.inputs[x].relative?
            if (model.basepath + model.inputs[x]).exist?
              model.inputs[x] = model.basepath + model.inputs[x]
            elsif (@input_dir + model.inputs[x]).exist?
              model.inputs[x] = @input_dir + model.inputs[x]
            else
              is_good = false
              ERROR(["Can not find #{model.inputs[x]} for #{model.name} instance #{x+1} at either",
                      "\t#{model.basepath + model.inputs[x]}",
                      "or",
                      "\t#{@input_dir + model.inputs[x]}"])
            end
          else
            unless model.inputs[x].exist?
              ERROR(["Can not find #{model.inputs[x]} for #{model.name} instance #{x+1}."])
              is_good = false
            end
          end
        end   ## unless model.inputs[x].class.to_s == "Pathname"
      end     ## end of model.inputs.each_index do |x| loop

      is_good = model.check && is_good
    end

    return is_good

  end   ## end of check

  #####################################################################
  # Register only valid IseJob configurations to the IseDatabase

  def register(do_sql=true)
    # insert the job into the IseDatabase
    # when do_sql is false only do a check on the job

    is_good = self.check

    if is_good
      self.insert_into_database if do_sql
    else
      puts "\nErrors were found in the configuration of"
      puts "IseJob: #{@name} -- #{@desc}\n"
      puts "The job was not registered in the IseDatabase because of the errors.\n"
    end

    print_log_counts

    if $DEBUG
      puts "\n\nRecap of IseJob Configuration"
      puts "=============================\n\n"
      self.show
      puts "\n\n"
    end

  end

  protected
  ##############################################################
  ## Insert the IseJob into the IseDatabase

  def insert_into_database

    if @id == 0
      a_job  = Job.new      ## adding a new job to the IseDatabase
    else
      a_job  = Job.find(@id)    ## replacing an existing job in the IseDatabase
    end

    a_job.name        = @name
    a_job.description = @desc
    
    a_job.router      = @router.to_s

    a_job.default_input_dir  = @input_dir.to_s
    a_job.default_output_dir = @output_dir.to_s

    IseDatabase.blame_user(a_job)

    a_job.save

    job_id = a_job.id

    a_job_config = JobConfig.find_all_by_job_id(job_id)

    # expected to find no configuration for this job; but, found something
    # so delete everything in the
    # job_config table with this job_id

    unless a_job_config.length == 0
      records_to_delete = []
      a_job_config.each { |ajc| records_to_delete << ajc.id }
      JobConfig.delete(records_to_delete)
    end

    @models.each do | my_model |

      puts "my_model is " + my_model.inspect  if $DEBUG

      is_good = true

      if my_model.id > 0
        begin
          a_model      = Model.find_by_name(my_model.name)
          unless my_model.id == a_model.id
            is_good = false
            ERROR([
              "IseDatabase internal system error.",
              "IseModel #{my_model.name} was found previously found as id #{my_model.id}",
              "Now it has id #{a_model.id} ... strange.  Please contact ISE support."])
          end
        rescue
          is_good = false
          ERROR([
            "IseDatabase internal system error.",
            "IseModel #{my_model.name} was found previously found as id #{my_model.id}",
            "Now it is not found ... strange.  Please contact ISE support."])
        end
      else
        a_model        = Model.new
      end

      puts "a_model is " + a_model.inspect if $DEBUG

      if is_good
        a_model.name        = my_model.name
        a_model.description = my_model.desc
        
        a_model.router      = my_model.router.to_s

        puts "Looking up this platform: #{my_model.platform}" if $DEBUG

        a_platform = Platform.find_by_name( my_model.platform )

        if a_platform
          a_model.platform_id = a_platform.id
        end

# FIXME: Clean this location field from the IseDatabase
#        a_model.location = my_model.location.to_s
        a_model.location = "(depreciated)"
        a_model.dll      = my_model.dll.to_s

        IseDatabase.blame_user(a_model)

        a_model.save

        model_id = a_model.id

        my_model.count.times do | model_instance_counter |    ## from 0 .. count-1
          a_job_config                = JobConfig.new
          a_job_config.job_id         = a_job.id
          a_job_config.model_id       = a_model.id

          a_job_config.model_instance = model_instance_counter + 1  ## Changes range to 1 .. count
          
          a_job_config.cmd_line_param = my_model.cmd_line_param[model_instance_counter]
          a_job_config.input_file     = my_model.inputs[model_instance_counter].to_s

          a_job_config.required       = my_model.required
          
          unless my_model.drones[model_instance_counter].length > 0
            my_model.drones[model_instance_counter] = "any"
          end

          a_node                      = Node.find_by_name(my_model.drones[model_instance_counter])

          if a_node
            a_job_config.node_id        = a_node.id
          else
            ERROR(["Internal System Error.  An IseDrone is missing from the nodes table."])
            pp my_model if $DEBUG
            a_job_config.node_id        = 0
          end

          unless a_job_config.node_id
            a_job_config.node_id = 0  # SMELL: Is this necessary?
          end

          a_job_config.save
        end
      end
    end

    INFO(["IseJob (id: #{job_id}) Successfully Registered in the IseDatabase."])

    puts JobConfig.find_all_by_job_id(job_id).columnized() if $DEBUG

  end

end     ### Class IseJob
