###################################################################################
###
##  IseDatabase: links to the backend RDBMS databases using ActiveRecord as the ORM
##
##	This file may be "required" outside of the IseJCL class stack and
##  the RAILS stack.
##
##

#############################################################
# MyCommonIseDbMethods
#
# with a nod to DRY, this class contains class methods
# which perform global actions that are required by both
# the command line environment and the rails environment; however,
# these methods must be performed at different times within the different
# environments.

class MyCommonIseDbMethods

  #########################################
  ## Load the database configuration from the
  ## $RAILS_ROOT/config/database.yml file

  def self.load_database_config_from_yaml

    ####################################
    ## IseDatabase Configuration Section

    database_yml_file = Pathname.new(ENV['RAILS_ROOT']) + 'config' + 'database.yml'

    $ISE_DB_CONFIG = YAML::load(ERB.new(IO.read(database_yml_file.to_s)).result)
    $DELILAH_CONFIG = $ISE_DB_CONFIG[ENV['RAILS_ENV']]

    # derive the GUID configuration from the Delilah configuration
    ## over-ride the database element using guid field from IseRun instance

    $GUID_CONFIG    = Hash.new
    $DELILAH_CONFIG.each_pair { |key, value| $GUID_CONFIG[key] = value }
    $GUID_CONFIG['database'] = 'dbname_of_unknown_run'
    
    # FIXME: This only works for the Delilah DB; screws up the GUID DB
    #        May need to subclass like we tried once before.
    ActiveRecord::Base.establish_connection $DELILAH_CONFIG

  end

end



if not defined? $ISE_RUNNING_ON_RAILS		## indicates that the environment has not been established

  # puts "IseDatabase is supporting a command line utility."

  $ISE_RUNNING_ON_RAILS = false

  require 'IseJCL_Utilities'	    ## support utility methods




  ## Ensures that the ISE environment is workable; basically
  ## that the setup_symbols script has been run

  establish_and_validate_environment  ## from IseJCL_Utilities

  unless $ISE_GOOD
    puts "Please correct the problems noted."
    puts "... terminating."
    exit
  end
  
  require 'IseDatabase_Utilities'	## support utility methods

#gem 'activerecord','=2.3.2'  ## FIXME: When everything gets bumped up to rails 2.3+ 

## See also:  http://groups.google.com/group/compositekeys/browse_thread/thread/8a21e996b9de8bc9
  require 'active_record'	## GEM: from Rails, Object Relationship Manager (ORM) on top of the back-end RDBMS
  require 'erb'           ## GEM: used within the database YAML config files
  require 'uuid'          ## GEM: creates the globally unique identifiers used during an IseJob runtime

#  require ($RAILS_ROOT + 'config' + 'initializers' + 'init_logger.rb').to_s
#  require ($RAILS_ROOT + 'config' + 'initializers' + 'mods_to_active_record.rb').to_s
#require 'active_record_mods'

  ##############################################################
  ## These are the kinds of adaptions that can be
  ## made in the  config/environment' file in order to
  ## facilitate easy connection to legacy databases that do not
  ## meet the standard Rails conventions

  # ActiveRecord::Base.table_name_prefix = "prefix_" ## Could be used to move
  # ActiveRecord::Base.table_name_suffix = "_suffix" ## extra db junk into Samson
  # ActiveRecord::Base.primary_key_prefix_type = :table_name_with_underscore ## or :table_name


  ####################################
  ## IseDatabase Configuration Section
  ## This has to be done at this point in order to
  ## establish the common ActiveRecord connection

  MyCommonIseDbMethods.load_database_config_from_yaml


  ################################################################
  ## Setup one connection to each supported database
  ##
  ## Don't get confused.  This section of code is only run when
  ## the command line utilities are executed.  This extension of
  ## ActiveRecord with the establish_connection macro is NOT EXECUTED
  ## when running within the RAILS environment.

  class DelilahDatabase < ActiveRecord::Base
    #    self.abstract_class = true
    self.establish_connection $DELILAH_CONFIG

  end


  ###############################################
  ## Define the models for the DelilahDatabase ##
  ###############################################

# FIXME: 1.9.1 Problem with Pathname class
unless ENV['RUBY_VERSION'] == "ruby 1.9.1"

  # 1.9.1 has a problem with this next line
  models_dir = $RAILS_ROOT + 'app' + 'models'

  models_dir.children.each do |model|
    require model.to_s if model.extname == '.rb'
  end

else

  require 'app_message'
  require 'debug_flag'
  require 'dispatcher_stat'
  require 'job_config'
  require 'job'
  require 'model'
  require 'name_value'
  require 'node'
  require 'platform'
  require 'run_message'
  require 'run_model_override'
  require 'run_model'
  require 'run_peer'
  require 'run'
  require 'run_subscriber'
  require 'status_code'
  require 'user'

end

  #  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
  ## all of the code above is specific to the command line environment.
  ##########################################################################################

else
  ## Put stuff here that is specific to the RAILS environment

  # puts "IseDatabase is running on rails."

end ## end of if $ISE_GOOD.nil?


##########################################################################################
## all of the code below supports both the command line and the rails environment
#  v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v


####################################
## IseDatabase Configuration Section
## Do this if necessary to ensure that the GUID database gets configured within
## both environments.

MyCommonIseDbMethods.load_database_config_from_yaml if not defined? $GUID_CONFIG


class GuidDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection $GUID_CONFIG
end


###################################################
## IseDatabase class collects methods that span
## tables or things that deal with the overall
## RDBMS configuration such as creating and ropping
## of the GUID database.

class IseDatabase


  ########################################################
  # This DbHack#ise_queen junk came from a time in which
  # the database.yml file was being modified.  Today
  # by convention the host parameter is now always ENV['ISE_QUEEN']
  # which should eliminate the need for this junk.
  #
  # NOTE: DbHack is still needed to support the GUID database.  The
  #       question becomes do we still need the GUID database concept?

  class DbHack < ActiveRecord::Base
  end
  
=begin
  def self.ise_queen
    DbHack.ise_queen
  end
=end

  ########################################################
  ## create the guid database in prep for an IseRun launch
  ## Attempt to establish a connection to the database.  Some
  ## adapters (sqlite3) will auto create the database if it does
  ## not exists.  Others like mysql and postgresql will throw
  ## an exception.  Catch the exception, do an adapter
  ## specific database creation.
  ##
  ## TODO: These methods are specific to the $GUID_CONFIG; they could be made generic
  ##
  ## SMELL: Untested against the big daddy RDBMS adapters; works with the FOSS crowd.

  def self.create_guid_database (my_guid = nil)

    $GUID_CONFIG['database'] = my_guid unless my_guid.nil?

    begin
      DbHack.establish_connection($GUID_CONFIG)
      DbHack.connection
    rescue
      case $GUID_CONFIG['adapter']
      when 'mysql', 'mysql2'
        DbHack.establish_connection($GUID_CONFIG.merge({'database' => nil}))
        DbHack.connection.create_database $GUID_CONFIG['database']
        DbHack.establish_connection($GUID_CONFIG)
      when 'postgresql'
        `createdb "#{$GUID_CONFIG['database']}" -E utf8`
      else
        ERROR(["Attempting to create a new database using an unsupported DB adapter.",
        "adapter: #{$GUID_CONFIG['adapter']}"])
        exit
      end ## end of case
    end   ## end of begin block

  end     ## end of self.create_guid_database

  #########################################
  # drop a database with the specified GUID

  def self.drop_guid_database(my_guid = nil)

    $GUID_CONFIG['database'] = my_guid if my_guid

    case $GUID_CONFIG['adapter']
    when 'mysql', 'mysql2'
      begin
        DbHack.establish_connection($GUID_CONFIG)
        DbHack.connection.current_database
        DbHack.connection.drop_database $GUID_CONFIG['database']
      rescue
      end
    when 'sqlite3'
      db_file = $ISE_ROOT + 'db' + $GUID_CONFIG['database']
      db_file.delete
    when 'postgresql'
      `dropdb "#{$GUID_CONFIG['database']}"`
    else
      ERROR(["Do not know how to drop the GUID database using this RDBMS adapter.",
             "adapter: #{$GUID_CONFIG['adapter']}"])
    end ## end of case

  end ## end of self.drop_guid_database



  ##############################################
  # Give this $USER credit for messing things up

  def self.blame_user (a_table)

    a_user = User.find_by_login($USER)

    unless a_user
      a_user = User.new
      a_user.login = $USER
      a_user.save
    end

    if a_table.id
      a_table.updated_by_user_id = a_user.id
    else
      a_table.created_by_user_id = a_user.id
      a_table.updated_by_user_id = a_user.id
    end

  end ## end of def self.blame_user (a_table)

end ## end of class IseDatabase

# puts "Goodbye from lib/IseDatabase.rb"
# puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"

#
## End of file IseDispatcher.rb
###############################

