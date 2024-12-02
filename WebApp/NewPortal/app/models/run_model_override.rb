################################################################
## RunModelOverride is the ActiveRecord ORM class to the "run_models_overrides" table in the
## Delilah database.
##

class RunModelOverride < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  belongs_to :run
  belongs_to :model
  belongs_to :user




  def self.set_override(debug_flags = "", cmd_line_param = "", all_users = false)
    if DebugFlag.validate(debug_flags)
      run_id   = 0
      user_id  = all_users ? 0 : User.find_by_account($USER).id
      model_id = 0
      instance = 0
      update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)
    end
  end



  def self.set_override_run(run, debug_flags = "", cmd_line_param = "", all_users = false)
    if DebugFlag.validate(debug_flags)
      run_id   = case run.class.to_s
        when "Fixnum" then Run.find(run)
        when "Run"    then run.id
        else -1
      end
      user_id  = all_users ? 0 : User.find_by_account($USER).id
      model_id = 0
      instance = 0
      update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)
    end
  end


  def self.set_override_model(model, debug_flags = "", cmd_line_param = "", all_users = false)
    if DebugFlag.validate(debug_flags)
      run_id   = 0
      user_id  = all_users ? 0 : User.find_by_account($USER).id
      model_id = case model.class.to_s
        when "Fixnum" then Model.find(model)
        when "Run"    then model.id
        else -1
      end
      instance = 0
      update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)
    end
  end


  def self.set_override_model_instance(model, instance, debug_flags = "", cmd_line_param = "", all_users = false)
    if DebugFlag.validate(debug_flags)
      run_id   = 0
      user_id  = all_users ? 0 : User.find_by_account($USER).id
      model_id = case model.class.to_s
        when "Fixnum" then Model.find(model)
        when "Run"    then model.id
        else -1
      end
      update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)
    end
  end


  def self.set_override_run_model(run, model, debug_flags = "", cmd_line_param = "", all_users = false)
    if DebugFlag.validate(debug_flags)
      run_id   = case run.class.to_s
        when "Fixnum" then Run.find(run)
        when "Run"    then run.id
        else -1
      end
      user_id  = all_users ? 0 : User.find_by_account($USER).id
      model_id   = case model.class.to_s
        when "Fixnum" then Model.find(model)
        when "Run"    then model.id
        else -1
      end
      instance = 0
      update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)
    end
  end



  def self.set_override_run_model_instance(run, model, instance, debug_flags = "", cmd_line_param = "", all_users = false)
    if DebugFlag.validate(debug_flags)
      run_id   = case run.class.to_s
        when "Fixnum" then Run.find(run)
        when "Run"    then run.id
        else -1
      end
      user_id  = all_users ? 0 : User.find_by_account($USER).id
      model_id   = case model.class.to_s
        when "Fixnum" then Model.find(model)
        when "Run"    then model.id
        else -1
      end
      instance = 0
      update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)
    end
  end

  def self.update_run_model_override(run_id, user_id, model_id, instance, debug_flags, cmd_line_param)

    rmo = RunModelOverride.find(:first, :conditions => "run_id = #{run_id} and user_id = #{user_id} and model_id = #{model_id} and instance = #{instance}")
    rmo = RunModelOverride.new if rmo.nil?
    rmo.run_id         = run_id
    rmo.user_id        = user_id
    rmo.model_id       = model_id
    rmo.instance       = instance
    rmo.debug_flags    = debug_flags
    rmo.cmd_line_param = cmd_line_param
    rmo.save
   
  end ## end of def self.update_run_model_override(run_id, user_id, model_id, 


end ## end of class RunModelOverride < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:43 -0500 2010

  create_table "run_model_overrides", :force => true do |t|
    t.integer "run_id",                       :default => 0, :null => false
    t.integer "user_id",                      :default => 0, :null => false
    t.integer "model_id",                     :default => 0, :null => false
    t.integer "instance",                     :default => 0, :null => false
    t.string  "cmd_line_param",                              :null => false
    t.string  "debug_flags",    :limit => 64,                :null => false
  end

  add_index "run_model_overrides", ["model_id"], :name => "index_run_model_overrides_on_model_id"
  add_index "run_model_overrides", ["run_id", "user_id", "model_id", "instance"], :name => "compound_index", :unique => true
  add_index "run_model_overrides", ["run_id"], :name => "index_run_model_overrides_on_run_id"
  add_index "run_model_overrides", ["user_id"], :name => "index_run_model_overrides_on_user_id"

