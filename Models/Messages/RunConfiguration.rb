###############################################
###
##   File:   RunConfiguration.rb
##   Desc:   Provides IseRun configuration data for the AADSE Simulation
##
#

require 'IseMessage'

class RunConfiguration < IseMessage
  def initialize
    super
    desc "Provides basic IseRun configuration data"
    #
    #      format_name       item_name
    item(:UINT32,           :run_id_)
    item(:double,           :created_at_)
    item(:UINT32,           :job_id_)
    item(:cstring,          :debug_flags_)
    item(:cstring,          :guid_)
    item(:cstring,          :input_dir_)
    item(:cstring,          :output_dir_)

  end
end
