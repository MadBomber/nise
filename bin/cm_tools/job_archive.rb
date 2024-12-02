#!/usr/bin/env ruby
###############################################################
###
##    File:  job_archive.rb
##    Desc:  archive an IseJob configuration in IseJCL format
#

# TODO: complete the job_archive.rb stub

require 'IseArchive'            ## Brings in everything related to IseJCL and IseDatabase
require 'highline/import'       ## GEM: high-level line oriented console interface

which_job = 0

all_jobs = Job.find(:all)

total_jobs = all_jobs.length

puts
puts

answer = choose do |menu|
  menu.select_by = :index
  menu.header    = "The following IseJobs are currently registered in the IseDatabase"
  menu.prompt    = "Which IseJob do you want to archive?"
  
  all_jobs.each_index do |x|
    menu.choice(all_jobs[x].name + ": " + all_jobs[x].description) do
      which_job = all_jobs[x].id
      out_file = File.new("#{all_jobs[x].name}.rb","w")
      IseArchive.job(which_job, out_file)
    end
  end
  
  menu.choice "Quit!"
end


# answer = ask("Which IseJob do you want to archive?\n(enter 0 to quit)  ", Integer) { |q| q.in = 0..total_jobs }

unless answer == "Quit!"
  puts "yada"
end


puts
puts
puts "Thanks for playing.  Tell your friends."
puts


## End of file
##############

