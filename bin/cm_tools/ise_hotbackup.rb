#!/usr/bin/env ruby
#########################################################################
###
##	File:	ise_hotbackup.rb
##	Desc:	Creates a restorable backup of ISE SVN repository
##        This script must be run as root
##
## SMELL: Use of system command line tools is not cross-platform
##
##  This program makes use of the following system command line tools:
##    svnlook ............. gets the latest revision for a repository
##    svnadmin ............ creates a hotcopy backup directory
##    tar      ............ compresses the directory to a *.tgz file
##    mysqldump ........... makes a backup of a database structure and content
#

require 'rubygems'
require 'systemu'
require 'pathname'
require 'pp'

# Add new projects for backup to the following list:
project_list = %w{
      AADSE
      AI
      ATT
      AWK
      C2C
      CBI_SIM
      Clips
      dislin
      dot_files
      EMSA
      etc
      Experiments
      GNU-Prolog
      HudsonHome
      ISE
      ISE_Portal
      Java
      MicroGrid
      MicroGridJava
      MicroGridSupport
      OS
      PHP
      PROLOG
      python
      reprovision_repos.rb
      shell_scripts
      Tcl
      template
      VRSIL_Tools
      wpt-www-dev
}


svnroot_dir       = Pathname.new("/media/James/svnroot")
hotcopy_base_dir  = Pathname.new("/media/Outlaw/svnrepo_backups")

# Get the name of this program
script_name = Pathname.new($0).basename ## required because on windoze $0 is a fullpath


##################################################
## Error Checking

unless hotcopy_base_dir.writable?
  puts
  puts "ERROR: Directory is not writable."
  puts "       #{hotcopy_base_dir}"
  puts "       As a safty mesaure only processes running on the IseQueen are allowed to"
  puts "       write to this directory.  You must execture this script on the IseQueen."
  puts
  exit -1
end


if RUBY_PLATFORM.include?('mswin32')
  running_on_microsoft = true
  user_account         = ENV['USERNAME']
  puts
  puts "WARNING: This program may not work on Windoze."
  puts
elsif RUBY_PLATFORM.include?('darwin')
  running_on_apple     = true
  user_account         = ENV['LOGNAME']   ## SMELL: Check this
elsif RUBY_PLATFORM.include?('linux')
  running_on_linux     = true
  user_account         = ENV['LOGNAME']
end

unless user_account == 'root'
  puts
  puts "WARNING: #{script_name} should be executed by the 'root' user."
  puts "         On MS Windows platforms it is desirable to be a local administrator of your computer." if running_on_microsoft
  puts "         You are currently using the login account: #{user_account}"
  puts

  puts "Do you want to continue using this account? (y/n)"
  users_answer = STDIN.gets
  users_answer.strip!.downcase!

  unless users_answer[0,1] == "y"
    puts "Terminating at user's request."
    exit -1
  end
  puts
  puts
end



#####################################
## Utility methods

def execute_on_command_line(the_cmd)
  puts "  Executing: #{the_cmd}"
  status, stdout, stderr = systemu(the_cmd)
end


########################################
## Main Backup Loop Over Each Project ##
########################################


project_list.each do |project|

  repo      = svnroot_dir + project

  status, stdout, stderr = systemu("svnlook youngest #{repo}")

  revision_number = stdout.strip

  bkup_dirname  = "#{project}_r#{revision_number}"
  bkup_dir      = hotcopy_base_dir + bkup_dirname

  tgz_filename  = "#{bkup_dirname}.tgz"
  tgz_file      = hotcopy_base_dir + tgz_filename

  puts "Backup of #{project} at revision #{revision_number} ..."

  unless bkup_dir.exist? or tgz_file.exist?

    execute_on_command_line("svnadmin hotcopy #{repo} #{bkup_dir}")
    Dir.chdir(hotcopy_base_dir.to_s)
    execute_on_command_line("tar czf #{tgz_filename} #{bkup_dirname}")

  else
    puts "  ... skipping because this revision already has a backup."
  end

end ## end of project_list.each do |project|

# This concludes the backup the Subversion Repositories
# Now backup the databases

puts
puts "#"*45
puts "Database Backup Section"
puts

datetime_stamp  = "_" + DateTime.now.strftime("%Y%m%d_%H%M%S") + ".tgz"

database_list.each do |database|

  db_name     = database[0]
  db_host     = database[1]
  db_user     = database[2]
  db_password = database[3]
  backup_dir  = database[4]

  puts "Backup of database #{db_name} on host #{db_host} ..."
  
  tgz_filename  = backup_dir + (db_name + datetime_stamp)
  sql_filename  = backup_dir + (db_name + '.sql')
  
  cmd_string  = "ssh ise@#{db_host} mysqldump #{db_name} --user=#{db_user} --password=#{db_password} > #{sql_filename}"

  
  rtn_code = execute_on_command_line(cmd_string)
  #pp rtn_code[2]

  rtn_code = execute_on_command_line("tar czf #{tgz_filename} #{sql_filename}")
  #pp rtn_code[2]

  rtn_code = execute_on_command_line("rm -fr #{sql_filename}")
  #pp rtn_code[2]



end ## end of database_list

