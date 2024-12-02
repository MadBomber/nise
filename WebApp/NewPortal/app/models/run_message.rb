################################################################
## RunMessage is the ActiveRecord ORM class to the "run_messages" table in the
## Delilah database.
##
## NOTE: ISE bleeding_edge does away with the run_messages table
#

require 'rubygems'
#gem 'composite_primary_keys', '=2.3.2'
require 'composite_primary_keys'


class RunMessage < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  self.primary_keys = [:run_id, :app_message_id]

  belongs_to  :run
  belongs_to  :app_message
  has_many    :run_subscribers
  
end ## end of class RunMessage < DelilahDatabase


# == Schema Information
#
# Table name: run_messages
#
#  id             :integer(4)      not null
#  run_id         :integer(4)      default(0), not null
#  app_message_id :integer(4)      default(0), not null
#  ref_count      :integer(4)      default(0), not null
#

__END__
Last Update: Tue Aug 10 14:06:43 -0500 2010

  create_table "run_messages", :force => true do |t|
    t.integer "run_id",         :default => 0, :null => false
    t.integer "app_message_id", :default => 0, :null => false
    t.integer "ref_count",      :default => 0, :null => false
  end

  add_index "run_messages", ["app_message_id"], :name => "index_run_messages_on_app_message_id"
  add_index "run_messages", ["run_id", "app_message_id"], :name => "compound_index", :unique => true
  add_index "run_messages", ["run_id"], :name => "index_run_messages_on_run_id"

