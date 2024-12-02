################################################################
## User is the ActiveRecord ORM class to the "users" table in the
## Delilah database.

class User < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  has_many :job_configs
  has_many :jobs,         :through => :job_config
  has_many :models,       :through => :job_config
  has_many :runs
  has_many :run_model_override


  def self.create (admin, login, name, email, phone_number)

    a_rec = self.new
    a_rec.admin        = admin
    a_rec.login        = login
    a_rec.name         = name
    a_rec.email        = email
    a_rec.phone_number = phone_number
    a_rec.save

    return a_rec

  end


  ###############################################
  def self.find_by_login_or_email(login_or_email)
    return find(:first, :conditions => ['login = ? OR email = ?', login_or_email, login_or_email])
  rescue
    return nil
  end
  
  ###############
  def self.get_me
    return find_by_login_or_email(ENV['USER'])
  end

end


__END__
Last Update: Tue Aug 10 14:06:48 -0500 2010

  create_table "users", :force => true do |t|
    t.boolean  "admin",                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login",        :limit => 32,                    :null => false
    t.string   "name",         :limit => 64
    t.string   "email",        :limit => 64
    t.string   "phone_number", :limit => 16
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
