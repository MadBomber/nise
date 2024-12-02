#!/usr/bin/env ruby
################################################################################################
###
##  File: annotate_models.rb
##  Desc: Extracts the table definitions from a schema.rb file and adds it to the bottom of
##        the model file.
#

require 'rubygems'
require 'pathname'
require 'activesupport'
require 'ostruct'
require 'systemu'

rails_root      = Pathname.new(ENV['RAILS_ROOT'])
schema_file     = rails_root + 'db' + 'schema.rb'
model_dir       = rails_root + 'app' + 'models'
data_dictionary = model_dir + 'data_dictionary.txt'

model_schemas_hash = Hash.new

skip_header   = true
table_name    = ""

pwd_dir = Pathname.pwd

unless rails_root == pwd_dir
  puts "ERROR: To ensure that the correct files are modified, you must be in the"
  puts "       the same directory as RAILS_ROOT."
  puts "       RAILS_ROOT: #{rails_root}"
  puts "       You're in:  #{pwd_dir}"
  exit -1
end

unless schema_file.exist?
  puts "Dumping latest schema ..."
  return_code, std_out, std_err = systemu("cd #{rails_root}; rake db:schema:dump")
  unless 0 == return_code
    puts "ERROR: Received non-zero return code from rake db:schema:dump => #{return_code}"
    puts "       std_out: #{std_out}"
    puts "       std_err: #{std_err}"
    exit(return_code)
  end
end

dd_file = File.open(data_dictionary.to_s, 'w')

# dd_file.puts "Last Update: #{Time.now}"

puts "Processing schema.rb ..."

schema_file.each_line do |a_line|
  w = a_line.split
  if 'create_table' == w[0]
    skip_header   = false

    table_name    = w[1].gsub('"','').gsub(',','')
    class_name    = table_name.singularize.camelize
    file_name     = model_dir + "#{table_name.singularize}.rb"
    
    model_schemas_hash[table_name]              = OpenStruct.new
    model_schemas_hash[table_name].table_name   = table_name
    model_schemas_hash[table_name].class_name   = class_name
    model_schemas_hash[table_name].file_name    = file_name
    model_schemas_hash[table_name].create_table = Array.new

  end

  unless skip_header
    model_schemas_hash[table_name].create_table << a_line
    if 't.' == a_line.strip[0,2]
      w = a_line.split
      field_name = w[1].gsub('"','').gsub(',','')
      field_type = w[0][2,99]
      colon_index = a_line.index(':')
      if colon_index
        more_stuff = "\t" + a_line[colon_index,999].squeeze(' ')
      else
        more_stuff = ""
      end
      dd_file.puts "#{field_name}\t#{field_type}\t#{table_name}#{more_stuff}"
    end
  end
end

dd_file.close

model_schemas_hash.each_key do |table_name|

  puts "#{table_name} ..."

  file_name = model_schemas_hash[table_name].file_name.to_s
  
  return_code, std_out, std_err = systemu("fgrep __END__ #{file_name}")
  
  if 0 == return_code
    File.rename(file_name, "#{file_name}~")
    model_file = File.open(model_schemas_hash[table_name].file_name, "w")
    bakup_file = File.open("#{file_name}~", 'r')
    bakup_file.each_line do |a_line|
      if "__END__" == a_line.chomp
        break
      end
      model_file.puts a_line
    end
    bakup_file.close
  else
    model_file = File.open(model_schemas_hash[table_name].file_name, "a")
  end
  
  model_file.puts "__END__"
  model_file.puts "Last Update: #{Time.now}"
  model_file.puts
  
  model_schemas_hash[table_name].create_table.each {|s| model_file.puts s}
  
  model_file.close

end



