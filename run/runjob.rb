#!/usr/bin/env ruby

require "mysql"
require "socket"
require 'optparse'

#if ENV['ACE_ROOT'] == nil
unless ENV['ACE_ROOT']
	puts "ACE_ROOT is not defined. We cannot continue."
end


#####
#  Define a Job, which consists of Peers

class Job

	def initialize(ex_id, debug_flag)
		@ex_id = ex_id
		@job_id = create_jobid()
		@debug_flag = debug_flag
		create_directory()
		@pp_array = Array.new()

		begin

			########################################################
			stmt = "Insert into JobProcesses (SELECT #{@job_id} as ID,DLL,Name,Count,Extra,External FROM RegisteredJobConfig WHERE ID= #{@ex_id});"
			#puts "Statement: #{stmt}"
			res = $dbh.query(stmt)

			if res.nil? && $dbh.affected_rows == 0 then
				puts "Statement: #{stmt}"
				puts "Job Configuration (#{@ex_id}) was not found"
			end

			########################################################3
			stmt = "Select * from JobProcesses where JobID = #{@job_id};"
			#puts "Statement: #{stmt}"
			res = $dbh.query(stmt)

			if res.nil? then
				puts "Statement: #{stmt}"
				puts "Processes for Job  (#{@job_id})was not found"
				printf "Number of rows affected: %d\n", $dbh.affected_rows
			else
				res.each_hash do |row|
					@pp_array << PeerProcess.new( @job_id, row["Name"], row["DLL"], row["Count"].to_i, row["Extra"], row["External"].to_i)
				end
				puts "Number of peers in this job: #{res.num_rows}"
				res.free
			end

		rescue Mysql::Error => e
			puts "Error code: #{e.errno}"
			puts "Error message: #{e.error}"
			puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		end
	end

	def Job.truncate
		begin
			#...  Remove the Job Databases
			stmt = "Select UUID from Job;"
			res = $dbh.query(stmt)
			if res.nil? then
				puts "Statement: #{stmt}"
                        else
                                res.each_hash do |row|
					theUUID = row["UUID"]
					res1 =  $dbh.query("DROP Database IF EXISTS `#{theUUID}`")
                                end
                                res.free
                        end

			#... Truncate the Tables
			tbl_array = %w( Job JobProcesses Message Model Peer Subscriber )
			#tbl_array.each { |stmt| puts("Truncate #{stmt};") }
			tbl_array.each { |stmt| res = $dbh.query("Truncate #{stmt};") }
		rescue Mysql::Error => e
			puts "Error code: #{e.errno}"
			puts "Error message: #{e.error}"
			puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		end
	end


	def get_jobid
		@job_id
	end


	def create_jobid
		begin
			res = $dbh.query("Insert into Job(Name,Description,UUID) Values('TEST','This is a TestJob',uuid());")
			job_id = $dbh.insert_id()
			puts "New Job ID: #{job_id}"
		rescue Mysql::Error => e
			puts "Error code: #{e.errno}"
			puts "Error message: #{e.error}"
			puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		end
		return job_id
	end

	def create_directory
	
		begin
			res = $dbh.query("Select UUID from Job where ID = #{@job_id};")
			if res.nil? then
				puts "Statement: #{stmt}"
				puts "UUID for Job  (#{@job_id}) was not found"
                        else
				if ENV["ISE_RUN"].class == String 
					new_dir = String.new(ENV["ISE_RUN"])
				elsif ENV["ISE_ROOT"].class == String
					new_dir = String.new(ENV["ISE_ROOT"])
				else
					new_dir = String.new("./")
				end
                                res.each_hash do |row|
					theUUID = row["UUID"]
					new_dir << "/" << theUUID
					puts "making directory #{new_dir}"
					Dir.mkdir new_dir			
					#ENV["ISE_TEST"] = new_dir

					res1 =  $dbh.query("Create Database `#{theUUID}`;")

                                end
                                res.free
                        end

		rescue Mysql::Error => e
			puts "Error code: #{e.errno}"
			puts "Error message: #{e.error}"
			puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		end
	end

	########
	#  Remove older files  (for now)  TODO control with cmdline flag

	def clean_directory
		Dir["output_*"].each do |fn|
			File.delete(fn)
		end
	end


	def run
		puts "------------------------------------------"
		@pp_array.each { |i| i.print() }
		puts "------------------------------------------"
		@pp_array.each { |i| i.run(@debug_flag) }
		puts "------------------------------------------"
	end

end


#######
# Define a Process that the Job Runs

class PeerProcess

	attr_accessor :job_id, :mname, :dll, :n, :extra, :ext

	def initialize(job_id, mname, dll, n=1, extra=nil, ext=0)
		@job_id = job_id
		@mname = mname
		@dll = dll
		@n = n
		@extra = extra
		@ext = ext
	end

	def print()
		Kernel.print "-j#{@job_id} -k#{@mname} -l#{@dll} -u(1...#{n}) #{@extra}"
		if @ext == 1 then
			Kernel.print "  EXTERNAL(#{@ext})"
		end
		Kernel.print "\n"
	end

	def run(debug_flag)
		for unit in 1...@n+1
			theCmd = "../SamsonPeer/peerd -j#{@job_id} -k#{@mname} -l#{@dll} -u#{unit} -c8001 -o" 
			if ( debug_flag) 
				theCmd += " -d#{$debug_flags}"
			end 
			theCmd += " #{@extra} &"
			if ( @ext == 0 ) then
				puts theCmd
				system theCmd
			else 
				puts "EXTERNAL: #{theCmd}"
			end
		end
	end
end


#####
#

class DispatcherMgr

	attr_accessor :id, :pid, :host

	def initialize
		@host = Socket::gethostname
		fill()
		if !running() then
			cleanup()
			start()		
		end
	end

	def fill
		begin

			########################################################
			stmt = "Select Peer.ID, Peer.PID from Peer,Node where Peer.NodeID = Node.ID and Peer.PeerKey= 'dispatcher' and Node.FQDN = '#{@host}';"
			puts "Statement: #{stmt}"
			res = $dbh.query(stmt)

			if res.nil? ||  res.num_rows==0 then
				@id = -1;
				@pid = -1;
			else
				res.each_hash do |row|
					@id = row["ID"].to_i
					@pid = row["PID"].to_i
				end
			end

		rescue Mysql::Error => e
			puts "Error code: #{e.errno}"
			puts "Error message: #{e.error}"
			puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		end
	end


	def running
		if @pid == -1 then
			puts "Dispatcher is NOT running on (#{@host})"
			return false
		else
			if ( FileTest.exist?( "/proc/#{@pid}" ) ) then
				puts "Dispatcher (#{@pid}) is running on (#{@host})"
				return true
   			else
				puts "Dispatcher (#{@pid}) is NOT running on (#{@host})"
				return false
			end
		end
	end

	def cleanup
		if @pid != 0 then
			stmt = "Delete from Peer where ID = #{@id}"
			res = $dbh.query(stmt)
		end
	end

	def start
		#saved_dir = Dir.getwd
		#Dir.chdir("../dispatcherd")
		#system "gnome-terminal -x ./dispatcherd -f xml/ise1.xml  &"
		#system "xterm -e ./dispatcherd -f xml/ise1.xml  &"
		system "xterm -e ./run_dispatcher.sh  &"
		sleep 3
		#Dir.chdir(saved_dir)
	end

end


##########################################################################################################
puts "Starting Samson Test Run\n"

$debug_flags  = "x"
#$debug_flags += ":DB"
#$debug_flags += ":OBJ"
#$debug_flags += ":PH"
$debug_flags += ":MODEL"
$debug_flags += ":APPMGR"
$debug_flags += ":APPBASE"
$debug_flags += ":ALL"
puts "DEBUG = #{$debug_flags}"

###################################################################################################
#.. this is tricky, later Linux distros do not allow LD_LIBRARY_PATH exist during some operations,
#   such as starting xwindows, but we are not putting the ACE libaries in a "standard" location.
#   So, we will set it to where I know the ACE is,
#

if ENV['LD_LIBRARY_PATH'] then 
	ENV['LD_LIBRARY_PATH'] += ":../lib"
else
	 ENV['LD_LIBRARY_PATH'] = "#{ENV['ACE_ROOT']}/lib:../lib"
end
puts "LD_LIBRARY_PATH = #{ENV['LD_LIBRARY_PATH']}"

########
# Open up database

begin
	# connect to the MySQL server
	#dbh = Mysql.real_connect("queen", "Samson", nil, "Samson")

	$dbh = Mysql.init
	$dbh.options(Mysql::READ_DEFAULT_GROUP, "samson")
	$dbh.real_connect

	# get server version string and display it
	puts "Server version: " + $dbh.get_server_info

rescue Mysql::Error => e
	puts "Error code: #{e.errno}"
	puts "Error message: #{e.error}"
	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

#
########

########
# default options
OPTIONS = {
  :debug       => false,
  :rerun       => 0,
  :config      => 1,
  :truncate    => false
}

puts "arguments: #{ARGV}"

ARGV.options do |o|
  script_name = File.basename($0)

  o.set_summary_indent('  ')
  o.banner =    "Usage: #{script_name} [OPTIONS]"
  o.define_head "ISE run script"
  o.separator   ""
  o.separator   "Mandatory arguments to long options are mandatory for " +
                "short options too."

  o.on("-c", "--config=val", Integer, "Configuration to load")      { |OPTIONS[:config]| }
#  o.on("-r", "--rerun=val", Integer, "Job to reuse")      { |OPTIONS[:rerun]| }
  o.on("-t", "--truncate", "Truncate Run Tables")      { |OPTIONS[:truncate]| }
  o.on("-d", "--debug", "Turn Debug On")            { |OPTIONS[:debug]| }

  o.separator ""

  o.on_tail("-h", "--help", "Show this help message.") { puts o; exit }

  o.parse!
end

puts "debug:     #{OPTIONS[:debug]}"
puts "rerun:     #{OPTIONS[:rerun]}"
puts "config:    #{OPTIONS[:config]}"
puts "truncate:  #{OPTIONS[:truncate]}"

#
########

########
#

if OPTIONS[:truncate] 
	Job.truncate()
else
	d = DispatcherMgr.new()
	j = Job.new(OPTIONS[:config],OPTIONS[:debug])
	j.run()
	puts "Run #{j.get_jobid} Started!"
end

$dbh.close if $dbh


