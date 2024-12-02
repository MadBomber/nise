=begin
IseModel: Colllects the necessary and sufficient information for the configuration of an
IseModel within an IseJob to be registered in the IseDatabase.
=end

require 'IseJCL_Utilities'  ## support utilities

require 'IseRouter'

class IseModel
  include IseRouter

  # Unique identifier for the IseModel
  attr_accessor   :id

  # Short descriptive name for the model
  attr_reader     :name

  # Single line description of the model
  attr_accessor   :desc

  # Hardware platform
  attr_reader     :platform

  # A boolean attribute that indicates that the dll is not a library but rather a stand-alone
  # executable
  attr_accessor   :executable

  # basename of the model's dynamic load library name. it is derived from location sans the
  # prefix and suffix used by the platform. The dll value is what will be used with the -l
  # parameter to the peerd process. ... and ... The dll attribute is also used for the basename
  # of the executable file when the executable attribute is true.  As an executable file it is
  # expected to be accessable via the system $PATH variable or equivalent process.
  attr_reader     :dll

  # Number of instances of this model within a job
  attr_accessor   :count
  
  # The control port(s) for man-in-the-loop control.  One per instance.  0
  attr_accessor   :control_port

  # Command Line Parameters to be sent to the model If a string, and count > 1 then the string
  # is the same for all instances.  OTOH, if an array, then the length of the array must be the
  # same as the count of instances.
  attr_reader     :cmd_line_param

  # Array of config file paths for each instance, one file per instance. if a string and the
  # instance count is greater than 1, then all instances will use the same input.
  attr_reader     :inputs

  # The IseDrone on which to execute this model. If other than null meaning 'any' and the count
  # is greater than one, if drones is a string then all instances are assigned to the same
  # drone.  If an array then the length of the array must be the same as the count.
  attr_reader     :drones

  # Default path to pre-pend to relative paths associated with this IseModel
  attr_reader     :basepath

  # Tells an IseJob controller wither this IseModel is required for the IseJob
  attr_reader     :required

  # Constructor Example
  #
  # target_model = IseModel.new(# The required parameters must be presented in the following
  # order
  #   "TargetModel",            # The name of the model; should be same as name on left side of =
  #   "generic flying target",  # A short single line description of the IseModel
  #   "i386-mswin32",           # The OS required by this IseModel
  #                             # ... defaults to the same as RUBY_PLATFORM
  #   "TargetModel",            # The name of this nodel's shared library (dll)
  #                             # ... defaults to the same as the model name
  #   false                     # Is IseModel a stand-alone executable
  #                             # ... defaults to false, i.e. nope, meaning its a library
  # )

  def initialize(name, desc, platform=nil, dll=nil, exec=false)
    @id             = 0
    @name           = name.gsub(/[ -]/, '_')  # name is a unique key and will be used on the command line
    @desc           = desc
    @platform       = platform ? platform.downcase : RUBY_PLATFORM


    # The fullpath to the DLL is no longer used because of the way in which ACE loads shared
    # objects.
    @location       = "(deprecated)"

    unless dll.nil?
      @dll          = Pathname.new dll
    else
      @dll          = Pathname.new name
    end

    @executable     = exec  ## if true, denotes this IseModel as a stand-alone executable

    @count          = 1
    @control_port   = []
    @cmd_line_param = []     ## name of the samson database field is "extra"
    @inputs         = []
    @drones         = []
    @basepath       = Pathname.new("")
    @router         = DEFAULT_ROUTER
    @required       = true

    self.quick_check

    puts "IseModel #{@name} initialized" if $DEBUG
  end


  # Convience method
  def executable?
    return @executable
  end


  # SMELL: Why this instead of attr_accessor ?
  def name=(a_name)
    @name = a_name
  end


  # Do a quick check of the name, desc, router and platform
  def quick_check

    is_good = true

    unless @name.length > 0
      ERROR(["No name was specified for this IseModel."])
      is_good = false
    end

    unless @desc.length > 0
      ERROR(["No desc (description) was specified for this IseModel."])
      is_good = false
    end

    unless $VALID_PLATFORMS.include? @platform
      ERROR([
          "The specified platform (#{@platform}) is not supported.",
          "Supported platforms are: #{$VALID_PLATFORMS.inspect}"])
      is_good = false
    end
    
     
    unless valid_router?
      ERROR([
          "The specified router @(router) os not supported.",
          "Supported message routers are: #(VALID_ROUTERS.join(', '))"
      ])
      is_good = false
    end

    if is_good
      a_model = Model.find_by_name(@name)
      if a_model
        puts "a_model is: " + a_model.inspect if $DEBUG
        @id     = a_model.id
        WARNING(["IseModel::quick_check: #{@name} already exists in the IseDatabase."])
        puts a_model.inspect if $DEBUG
      else
        puts "New IseModel: #{@name} -- #{@desc}" if $DEBUG
      end
    end

  end


  # Replace an existing IseModel in the database

  # TODO: IseModel.replace(new_model) needs more testing
  def self.replace(new_model)  ## must be an IseModel

    is_good = true

    unless new_model.class.to_s == "IseModel"
      ERROR(["Parameter must be an IseModel.",
          "The parameters passed is a #{new_model.class}"])
      is_good = false
      return is_good
    end

    unless new_model.check
      ERROR(["The replacement IseModel did not pass its validity checks.",
          "Correct the problems noted and try again."])
      is_good = false
      return is_good
    end

    # Its a real IseModel that passes the validy checks Is there an existing IseModel in the
    # IseDatabase by this name?

    existing_model = Model.find_by_name(new_model.name)

    unless existing_model
      ERROR(["There is no IseModel in the IseDatabase by this name.",
          "Attempting to replace IseModel named #{new_model.name}."])
      is_good = false
      return is_good
    end

    existing_model.name         = new_model.name
    existing_model.description  = new_model.description

    puts "Looking up this platform: #{new_model.platform}" if $DEBUG

    a_platform = Platform.find( :first, :conditions => ["name like ?", new_model.platform] )

    if a_platform
      existing_model.platform_id = a_platform.id
    end

    existing_model.location = new_model.location

    existing_model.dll = new_model.dll
    
    existing_model.router = new_model.router

    IseDatabase.blame_user(existing_model)

    existing_model.save

    new_model.id = existing_model.id

    return is_good

  end   ## end of def self.replace(new_model)
  

  # Delete an existing IseModel in the database ## TODO: IseModel.delete(pld_model_name) needs
  # more testing
  def self.delete(old_model_name) ## must be a string

    is_good = true

    unless old_model_name.class.to_s == "String"
      ERROR(["Parameter must be a String.",
          "The parameters passed is a #{old_model_name.class}"])
      is_good = false
      return is_good
    end

    existing_model = Model.find_by_name(old_model_name)

    unless existing_model
      ERROR(["There is no IseModel in the IseDatabase by this name.",
          "Attempting to replace IseModel named #{old_model_name}."])
      is_good = false
      return is_good
    end

    Model.delete(existing_model.id)

  end

  # Converts the major attributes of an IseModel into a string
  def to_s    ## Convert object to string

    a_str  = "\n#{@name} (Count: #{@count}) - #{@desc}\n"
    a_str += "\tRequired .... #{@required}#{required? ? ' this model is optional within this IseJob' : ''}\n"
    a_str += "\tPlatform .... #{@platform}\n"
    a_str += "\tLocation .... #{@location}\n"
    a_str += "\tDLL ......... #{@dll}\n"
    a_str += "\tMsg Router .. #{@router}\n"
    a_str += "\tBasepath .... #{@basepath}\n"

    a_str += "\tInstance Table:\n"
    a_str += sprintf "\t| %3s | %-10s | %-12s | %-55s |\n", "#", "IseDrone", "Parameter", "Input File Path"
    (1..@count).each do |x|
      a_str += sprintf "\t| %3.0d | %-10s | %-12s | %-55s |\n", x, @drones[x-1], @cmd_line_param[x-1], @inputs[x-1]
    end

    return a_str

  end


  # Utility function used to print to STDOUT the major attributes on an IseModel
  def show   ## Print the object
    puts self.to_s
  end


  # Assign and validate as necessary the execution platform required by this model.
  def platform=(a_platform)
    @platform = a_platform.downcase
    unless $VALID_PLATFORMS.index(@platform)
      ERROR(["Invalid execution platform specified for model #{@name}",
          "Invalid platform: #{@platform}",
          "Supported platforms are: ",
          $VALID_PLATFORMS])
    end
  end


  # Assign and validate as necessary the drones required by this model
  def drones=(a_str_array)
    @drones = [a_str_array].flatten
    unless @count == @drones.length
      WARNING(["The number of IseDrones specified ( #{@drones.length} ) does not match the IseModel's instance count ( #{@count} )"])
    end

    @drones.each_index do |x|
      if @drones[x] == "any"
        @drones[x] = ""
      end
    end

    @drones.each do | requested_drone |
      if $VALID_DRONES.include?(requested_drone)
        unless $DRONE_PLATFORM[requested_drone] == @platform
          ERROR(["The requested drone, #{requested_drone}, is not the same kind",
              "of platform specified for this IseModel.",
              "The IseModel #{@name} specified a #{@platform} platform.",
              "The IseDrone, #{requested_drone} is a #{$DRONE_PLATFORM[requested_drone]} platform."])
          is_good = false
        end
      else
        unless requested_drone.length == 0
          ERROR(["The requested drone, #{requested_drone}, is not part of this IseCluser."])
          is_good = false
        end
      end ## end of if $VALID_DRONES.include?
    end   ## end of @drones.each do
  end     ## end of def drones=


  # Assign and validate as necessary the cmd_line_param required by this model
  def cmd_line_param=(a_str_array)
    @cmd_line_param = [a_str_array].flatten
    unless @count == @cmd_line_param.length
      WARNING(["The number of cmd_line_param specified ( #{@cmd_line_param.length} ) does not match the IseModel's instance count ( #{@count} )"])
    end

    @cmd_line_param.each do | a_param |
      if a_param.length > 0
        unless a_param[0,1] == "-"
          WARNING(["Expected a leading dash '-' on the parameter: #{a_param}"])
        end
      end
    end   ## end of @cmd_line_param.each do
  end     ## end of def cmd_line_param=


  # Assign and validate as necessary an optional default path for use wtih all relative paths
  # associated with this IseModel.
  def basepath=(a_path)
  
    @basepath = Pathname.new(a_path)
    if @basepath.absolute?
      unless @basepath.exist? and @basepath.directory?
        ERROR([ "basepath, if specified must be an existing directory.",
                "basepath [#{@basepath}]"])
      end
    end
  end ## end of def basepath=


  # Assign and validate as necessary the input files for each model instance.  It is assumed
  # that there is one and only one input file associated with each instance of a model.
  def inputs=(an_array)
    @inputs = [an_array].flatten
    @inputs.each_index do | x |
      if @inputs[x].length > 0
        @inputs[x] = Pathname.new(@inputs[x])   ### convert the string object into a Pathname
      end
    end
  end ## end of def inputs=


  # Assign and validate as necessary a shared library (DLL) name that comprises the executable
  # for this IseModel
  #
  # NOTE: The ACE shared library load function for both MS Windows and Linux
  #       only takes the basename.  The full path is not used by ACE.  If fact,
  #       the ACE developers does not allow the use of a full path it is a security risk.
  #       The ACE behaviour is to load the basename with appropriated platform
  #       extension from the load library path system environment variable.
  #       On most *nix systems that is the "LD_LIBRARY_PATH" variable.  On MacOSX
  #       it is the "DYLD_LIBRARY_PATH" variable.  On MS Windows XP it is just the
  #       common "Path" variable.
  #
  #       The IseRubyPeer duplicates this behavior to the extent that Ruby 'libraries" are
  #       loaded based upon the value of the "RUBYLIB" system environment variable.
  #

  def dll= (a_parm)

    parm_class = a_parm.class.to_s

    case parm_class
    when "String" then
      a_pathname = Pathname.new a_parm
    when "Pathname" then
      a_pathname = a_parm
    else
      ERROR([ "Internal system error.  Expecting parameter of String or Pathname.",
          "Got #{parm_class} instead."])
    end

    # extname returns the file extension including the period dirname returns the path without
    # the basename basename returns just the file component

    a_dirname     = a_pathname.dirname      # returns a Pathname
    the_extension = a_basename.extname      # returns a String
    a_basename    = a_pathname.basename

    # ignore the path if specified

    unless 0 == a_dirname.to_s.length
      WARNING([ "A path is not required on the DLL name.",
          "Using #{a_basename} instead of #{a_pathname}"])
    end

    # Do not mess with the basename if it is an executable
    unless executable?

      # remove the extension if specified

      unless 0 == the_extension.length
        temp_str     = a_basename.to_s
        temp_len     = temp_str.length
        new_basename = temp_str[0,temp_len - the_extension.length]

        WARNING([ "An extension is not required on the DLL name.",
            "Using #{new_basename} instead of #{a_basename}"])

        a_basename = Pathname.new new_basename
      end

      # remove the 'd' on MS Windows for DEBUG compiled libraries

      if @platform.include?('mswin32')  ## remove the debug 'd' from the basename if present
        temp_str     = a_basename.to_s
        temp_len     = temp_str.length - 1
        if 'd' == temp_str[temp_len, 1]
          temp_str = temp_str[0, temp_len]
          WARNING([ "On MS Windows platforms, the last character of a complete DLL name compiled",
              "in DEBUG mode is 'd' HOWEVER, it is not necessary to specify the 'd' character",
              "within ISE since ACE automaticall searches for both the correctly name file.",
              "ISE will use #{temp_str} instead of #{a_basename}"])
          a_basename = Pathname.new temp_str
        end ## if 'd' == temp_str[temp_len, 1]
      end   ## if @platform.include?('mswin32')

      # remove any standard library prefixes

      pf_len  = $MODEL_PREFIX[@platform].length
      unless 0 == pf_len
        if $MODEL_PREFIX[@platform] == @dll.to_s[0, pf_len]
          temp_str = a_basename.to_s[pf_len, temp_str.length]
          WARNING(["It is not necessary to specify the DLL prefix on this platform.",
              "Using #{temp_str} instead of @{a_basename}"])
          a_basename = Pathname.new temp_str
        end
      end

    end ## end of unless executable?

    @dll = a_basename

  end ## end of def dll= (a_string)
  
  
  # Set the required attribute to a boolean value.  The default is true
  
  def required=(a_boolean=true)
    if TrueClass == a_boolean.class or FalseClass == a_boolean.class
      @required = a_boolean
    else
      throw "Value must be either true or false"
    end
  end
  
  
  def required?
    @required
  end
  


  # Check / Validate all supplied and defaulted attributes on this IseModel.  Return FALSE if
  # there are any problems that prevent this IseModel from being registered with an IseJob in
  # the IseDatabase.
  #
  # SMELL: Assumption is that IseModel.check will only be invoked by IseJob.check
  #        Several things look like they will break if multiple checks are performed
  #        from the job config file.
  def check() # Validity check the object

    # Assume everything is good; then find things that are not good
    is_good = true

    # Validate the name of the model
    unless @name.length > 0
      @name = "unknown"
      ERROR(["Model name must be provided."])
      is_good = false
    end


    # TODO: More thought on the relationship between an existing IseModel and one being defined
    # for an IseJob

    # TODO: Do we automatically replace the existing one, use it, throw an error or what,,,



    # Validate the description of the model
    unless @desc.length > 0
      @desc = "unknown"
      ERROR(["Model desc (description) must be provided."])
      is_good = false
    end


    # Validate the basepath of a model
    if @basepath.to_s.length > 0 then
      # If a basepath is supplied it must be a directory
      unless @basepath.directory?
        is_good = false
        ERROR(["basepath, if specified must be a directory.",
            "Invalid basepath is: " + @basepath.to_s])
      end
    end

    # Validity check the model's platform
    unless @platform.length > 0 && $VALID_PLATFORMS.index(@platform)
      ERROR(["Invalid execution platform specified for model #{@name}",
          "Invalid platform: #{@platform}",
          "Supported platforms are: ",
          $VALID_PLATFORMS])
      is_good = false
    end

     
    unless valid_router?
      ERRPR([
          "The specified router @(router) os not supported.",
          "Supported message routers are: #(VALID_ROUTERS.join(', '))"
      ])
      is_good = false
    end
    

    # The dll is in its final form; now check against the load library path

    # FIXME: where_is assumes that execution platform is same as platform specified for model.

    # SMELL: Assumes a homogenious cluster

    # TODO:  Consider case of a hetrogenious cluser where this script is being run on linux and
    # we're checking a windows model

    #    puts "##################################################"
    #    pp self

    dll_locations = where_is(@platform, @dll)

    if dll_locations

      if dll_locations.length > 1
        WARNING(["The DLL file for #{@name} - #{@desc}",
            "has been found in several locations based upon this platform's",
            "load library path.",
            "Locations are: #{dll_locations.inspect}"])
      end

      if dll_locations.length == 0
        WARNING(["The DLL file for #{@name} - #{@desc}",
            "has not been found in any locations based upon this platform's",
            "load library path."])
      end

      if dll_locations.length == 1

        unless @location.to_s == dll_locations[0].to_s

          WARNING(["The DLL file for #{@name} - #{@desc}",
              "has been found in a location based upon this platform's",
              "load library path that is different from the location specified.",
              "  The specified location:  #{@location}",
              "  The discovered location: #{dll_locations[0]}",
              "If the specified location is the correct one for this IseJob,",
              "the load library path must be modified to include the path:",
              "  @location.path",
            ])
          #          is_good = false

        end ## end of unless @location.to_s == dll_locations
      end   ## end of if dll_locations.length == 1
    else
      # FIXME: can not check paths on some other computer besides the current localhost
      #      is_good = false
    end     ## end of if dll_locations



    # Validate the drones assignment

    # TODO: Refactor validate drones into its own private method

    @drones.each do | requested_drone |

      if requested_drone != "any" && $VALID_DRONES.include?(requested_drone)
        unless $DRONE_PLATFORM[requested_drone] == @platform
          ERROR(["The requested drone, #{requested_drone}, is not the same kind",
              "of platform specified for this IseModel.",
              "The IseModel #{@name} specified a #{@platform} platform.",
              "The IseDrone, #{requested_drone} is a #{$DRONE_PLATFORM[requested_drone]} platform."])
          is_good = false
        end
      else
        unless requested_drone.length == 0 || requested_drone == "any"
          ERROR(["The requested drone, #{requested_drone}, is not part of this IseCluser."])
          is_good = false
        end
      end

    end ## of @drones.each do

    if @count > @drones.length
      WARNING(["Fewer IseDrones were specified than the IseModel's instance count.",
          "Defaulting to 'any' for remaining instances."])
      x = @count - @drones.length
      x.times { @drones.push("") }

    end

    if @count < @drones.length
      ERROR(["More IseDrones have been specified than IseModel's count."])
      is_good = false
    end

    # Validate the instance count of the model
    unless @count > 0
      ERROR(["'count' must be numeric and greater than zero."])
      is_good = false
    end

    # Validate the command line cmd_line_param

    @cmd_line_param.each_index {|x|@cmd_line_param[x].strip if "String" == @cmd_line_param[x].class.to_s} ## remove white space around string

    @cmd_line_param.each do |a_param|
      if a_param
        if a_param.length > 0 then
          unless a_param[0,1] == "-"
            WARNING(["Command line param for IseModel #{name} does not start with a dash.",
                "parameter is: #{a_param}"])
          end
        end
      end
    end

    if @count < @cmd_line_param.length
      ERROR(["More command line parameters were specified than 'count' instances."])
      is_good = false
    end

    if @count > @cmd_line_param.length
      WARNING(["Fewer command line parameters were specified than 'count' instances.",
          "Defaulting remaining instances to the last specified set of command line parameters."])
      x = @cmd_line_param.length - 1
      default_param = @cmd_line_param[x]
      y = @count - @cmd_line_param.length
      y.times {@cmd_line_param.push(default_param)}
    end

    # Validate every specified input file

    unless @inputs.length == @count
      # Make this a warning.  Some models may not have input files.
      WARNING(["Number of input files does not match the #{@name}'s count.",
          "Input files: " + @inputs.length.to_s + " Model count: #{@count}"])
    end

    if @count > 1 and @inputs.length > 0 then
      unless @inputs.length == @count
        # if 1 instance has an input file then all instances must have an input file
        ERROR(["Number of input files does not match the #{@name}'s count.",
            "Input files: " + @inputs.length.to_s + " Model count: #{@count}"])
        is_good = false
      end
    end

    @inputs.each_index do | x |
      unless @inputs[x].to_s.length == 0
        unless @inputs[x].class.to_s == "Pathname"
          a_string = @inputs[x]
          @inputs[x] = Pathname.new(a_string)
        end

        unless @inputs[x].absolute?
          @inputs[x] = @basepath + @inputs[x]
        end
      end
    end

    @inputs.each do |a_file|
      if a_file.to_s.length > 0
        unless a_file.file?
          ERROR(["Specified input file for IseModel #{@name} does not exist.",
              "Invalid input file: '#{a_file}'"])
          is_good = false
        end
      end
    end

    return is_good

  end     ## end of def check
end       ## end of class IseModel
