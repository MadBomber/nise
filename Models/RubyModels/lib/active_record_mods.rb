##################################################
###
##  File:  config/initializers/mods_to_active_record.rb
##  Desc:  Extend ActiveRecord with the columnized method.
##         This method is defined in IseJCL_Utilities.  It
##         pretty prints a has array structure.
##
##  These extensions to ActiveRecord are also required
##  by lib/IseDatabase.rb in support of command line utilities.
#

require 'IseJCL_Utilities'

class ActiveRecord::Base

#  @@the_ise_queen = ""


  #################################
  ## formatted column dump of table

  def columnized(options = {})
    [*self].columnized(options)     ## Defined in IseJCL_Utilities as a new method in Array
  end

  ######################################
  ## list all entries in the RDBMS table
  ## using the columnized method

  def self.list_all
    all_rows = self.find(:all)
    if all_rows.empty?
      puts "Table #{self.model_name} is empty."
    else
      puts all_rows.columnized
    end
  end


  ###########################################################
  ## The IP address of the :host for all active _records
  ## is supposed to be the $ISE_QUEEN; however, since that
  ## information comes from the $RAILS_ENV/config/database.yml
  ## file during rails initialization, it is possible that the
  ## file is out of sync with the shell's environment
  ## variable.
  ##
  ## This method supports error checking to ensure that the database.yml
  ## file and the environment varialbe are the same.
  ##
  ## NOTE: by convention the database.yml file always uses the
  ##       ENV['ISE_QUEEN'] as its host value
  #
=begin
  def self.ise_queen
    return @@the_ise_queen if @@the_ise_queen.length > 0
    @@the_ise_queen = ""
    
    debug_me {"self.connection"}
    
    live_config = YAML.parse(self.connection.to_yaml)['config'].value
    live_config.each_pair do |k,v|
      @@the_ise_queen = live_config[k].value if k.value == ':host'
    end

    raise "HOST is not the $ISE_QUEEN" if @@the_ise_queen != ENV['ISE_QUEEN']

    return @@the_ise_queen
  end
=end


end ## end of class ActiveRecord::Base extensions

# $stderr.puts "\nThe IseDatabase is being accessed on: #{User.ise_queen}\n\n"
