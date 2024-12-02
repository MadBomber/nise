#!/usr/bin/env ruby
###############################################################
###
##    File:  list_job_config.rb
##    Desc:  display an IseJob configuration from the IseDatabase
#


require 'IseJCL'            ## Brings in everything related to IseJCL and IseDatabase
require 'highline/import'       ## GEM: high-level line oriented console interface

which_job = 0

all_jobs = Job.find(:all)

total_jobs = all_jobs.length

puts
puts

answer = choose do |menu|
  menu.select_by = :index
  menu.header    = "The following IseJobs are currently registered in the IseDatabase"
  menu.prompt    = "\nWhich IseJob configuration do you want to display?"
  
  all_jobs.each_index do |x|
    menu.choice(all_jobs[x].name + ": " + all_jobs[x].description) do
      which_job = all_jobs[x].id
      list_job which_job
    end
  end
  
  menu.choice "Quit!"
end


#unless answer == "Quit!"
#  puts "yada"
#end


puts
puts


## End of file
##############

