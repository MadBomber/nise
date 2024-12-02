#!/usr/bin/env ruby

require "mysql"
require "socket"

########
#  Remove older files  (for now)  TODO control with cmdline flag

def del_ouput
	Dir["output_*"].each do |fn|
		File.delete(fn)
	end
end



#####
#  Define a Job, which consists of Peers

class Job

	def initialize(ex_id)
		@ex_id = ex_id
		@job_id = create_jobid()
		create_directory()
		@pp_array = Array.new()

		begin

			########################################################
			stmt = "Insert into JobProcesses (SELECT #{@job_id} as ID,DLL,Name,Count,Extra FROM RegisteredJobConfig WHERE ID= #{@ex_id} ORDER BY SortOrder);"
			res = $dbh.query(stmt)

			if res.nil? && $dbh.affected_rows == 0 then
				puts "Statement: #{stmt}"
				puts "Job Configuration (#{@ex_id}) was not found"
			end

			########################################################3
			stmt = "Select * from JobProcesses where JobID = #{@job_id};"
			res = $dbh.query(stmt)

			if res.nil? then
				puts "Statement: #{stmt}"
				puts "Processes for Job  (#{@job_id})was not found"
				printf "Number of rows affected: %d\n", $dbh.affected_rows
			else
				res.each_hash do |row|
					@pp_array << PeerProcess.new( @job_id, row["Name"], row["DLL"], row["Count"].to_i, row["Extra"])
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
			res = $dbh.query("Select UUID from  Job where ID = #{@job_id};")
			if res.nil? then
				puts "Statement: #{stmt}"
				puts "UUID for Job  (#{@job_id}) was not found"
                        else
                                res.each_hash do |row|
					puts "making directory #{row['UUID']}"
					Dir.mkdir row["UUID"]			
					ENV["ISE_TEST"] = row["UUID"]
                                end
                                res.free
                        end

		rescue Mysql::Error => e
			puts "Error code: #{e.errno}"
			puts "Error message: #{e.error}"
			puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		end
	end

	def run
		puts "------------------------------------------"
		@pp_array.each { |i| i.print() }
		puts "------------------------------------------"
		@pp_array.each { |i| i.run() }
		puts "------------------------------------------"
	end

end


#######
# Define a Process that the Job Runs

class PeerProcess

	attr_accessor :job_id, :mname, :dll, :n, :extra

	def initialize(job_id, mname, dll, n=1, extra=nil)
		@job_id = job_id
		@mname = mname
		@dll = dll
		@n = n
		@extra = extra
	end

	def print()
		puts "-j#{@job_id} -k#{@mname} -l#{@dll} -u(1...#{n}) #{@extra}"
	end

	def run()
		for unit in 1...@n+1
			theCmd = "../SamsonPeer/peerd -j#{@job_id} -k#{@mname} -l#{@dll} -u#{unit} -c8001 -o -d#{$debug_flag} #{@extra} &"
			puts theCmd
			system theCmd
		end
	end
end

#####
#

def check_dispatcher

	host = Socket::gethostname
	
	begin

		########################################################3
		stmt = "Select Peer.ID from Peer,Node where Peer.NodeID = Node.ID and Peer.PeerKey= 'dispatcher' and Node.FQDN = '#{host}';"
		res = $dbh.query(stmt)

		if res.nil? ||  res.num_rows==0 then
			#puts "Statement: #{stmt}"
			puts "Dispatcher is not running on (#{host})"
			return false;
		else
			puts "Dispatcher is running on (#{host})"
			return true;
		end

	rescue Mysql::Error => e
		puts "Error code: #{e.errno}"
		puts "Error message: #{e.error}"
		puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		return false
	end



end


##########################################################################################################
puts "Starting Samson Test Run\n"

$debug_flag  = "x"
#$debug_flag += ":DB"
#$debug_flag += ":OBJ"
#$debug_flag += ":PH"
#$debug_flag += ":MODEL"
#$debug_flag += ":APPMGR"
#$debug_flag += ":APPBASE"
#$debug_flag += ":ALL"
puts "DEBUG = #{$debug_flag}"


ENV['LD_LIBRARY_PATH'] += ":../lib"
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
#

if check_dispatcher() then
	j = Job.new(1)
	j.run()
end

$dbh.close if $dbh

puts "Run #{$job_id} Started!"

