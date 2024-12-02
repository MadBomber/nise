################################################################
## DebugFlag is the ActiveRecord ORM class to the "debug_flags" table in the
## Delilah database.
##

$debug_flag_seperator = ':'    ## seperator between the debug_flags

class DebugFlag < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  ##########################################
  ## Utilities related to the debug_flags ##
  ## runs, and run_model_overrides tables ##
  ##########################################

  def self.create (name, desc)
  
    a_rec = self.new
    a_rec.name = name
    a_rec.desc = desc
    a_rec.save
    
  end



  def self.validate(a_df)

    # expecting String or Array
    
    is_good   = true
    bad_flags = []
    
    if a_df.class.to_s == "String"
      return is_good if a_df.length == 0
      a_df = a_df.split($debug_flag_seperator)
    elsif a_df.class.to_s != "Array"
      ERROR(["Bad parameter class.  Expecting String or Array.",
             "Bad class:     #{a_df.class}",
             "Bad parameter: #{a_df.inspect}"])
      is_good = false
      return is_good
    end
    
    a_df.each do | df |
      a_record = DebugFlag.find_by_name(df)   ## SMELL: appears to be case insensitive
      unless a_record
        is_good = false
        bad_flags += [df]
      end
    end
    
    unless is_good
      ERROR(["Invalid debug flag(s).",    ## rails has puralize function ???
             "Bad flags are: #{bad_flags.inspect}"])
    end
    
    return is_good

  end ## end of def self.validate(a_df)


end ## end of class DebugFlag < DelilahDatabase

__END__
Last Update: Tue Aug 10 14:06:49 -0500 2010

  create_table "debug_flags", :force => true do |t|
    t.string "name", :limit => 32,   :default => "", :null => false
    t.string "desc", :limit => 1024, :default => "", :null => false
  end

  add_index "debug_flags", ["name"], :name => "index_debug_flags_on_name", :unique => true

