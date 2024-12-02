#!/usr/bin/env ruby
##################################################################
###
##  File: build_user.rb
##  Desc: Builds the basic ISE User account from files
##        co-located in the current directory.  This code must
##        not use any GEM extensions only Ruby 1.8.7 and its
##        standard library.
##
##  NOTE: This program is expecting to be run from the configure_ise_user_account
##        where the system environment variables ISE_ROOT and ISE_PROXY are set.
#

$debug  = false

require 'rubygems'
require 'pathname'
require 'erb'

$HOME       = Pathname.new(ENV['HOME'])
$BACKUP_DIR = $HOME + 'dot_file_backups'


if $debug
  def system(a_string)
    puts "  SYSTEM: #{a_string}"
  end
end




unless $BACKUP_DIR.exist?
  $BACKUP_DIR.mkdir unless $debug
end

$ISE_ROOT   = ENV['ISE_ROOT']
$ISE_PROXY  = (ENV['ISE_PROXY'] || '').strip


me          = Pathname.new(__FILE__)
my_dir      = me.dirname
me_basename = me.basename
children    = my_dir.children

backup_file_indicators  = ['~', '.bak']

exclude_these = [me, me_basename, my_dir+'.svn', my_dir+'.git', my_dir+'README.txt']

its_a_backup  = false

children.each do |c|
  if exclude_these.include?(c)
    puts "excluding #{c}" if $debug
  else
    backup_file_indicators.each do |b|
      tag_len       = b.length
      its_a_backup  = false
      if c.to_s[-tag_len,tag_len] == b
        puts "bkup excluded #{c}" if $debug
        its_a_backup= true
        break
      end
    end
    unless its_a_backup
      puts "processing #{c} ..." if $debug
      
      dir_opt = c.directory? ? '-R ' : ''
      
      if '.erb' == c.extname
        puts "processing an erb template #{c.basename}..." if $debug
        erb = ERB.new(File.read(c.to_s))
        home_c = $HOME + c.basename.to_s.gsub('.erb', '')
        puts "  home_c is #{home_c}" if $debug
        system "cp #{dir_opt}#{home_c} #{$BACKUP_DIR}" if home_c.exist?
        if $debug
          puts erb.result
        else
          home_file = File.open(home_c.to_s, 'w')
          home_file.puts erb.result
          home_file.close
        end
      else
        home_c = $HOME + c.basename

        # TODO: director contents are not processed for ERB templates
        #       Need to create a recursive method to process directory
        #       contents.
        
        system "cp #{dir_opt}#{home_c} #{$BACKUP_DIR}" if home_c.exist?
        system "cp #{dir_opt}#{c} #{$HOME}"
      end ## end of if '.erb' == c.extname
    end ## end of unless its_a_backup
  end ## end of if exclude_these.include?(c)
end ## end of children.each do |c|

system "cd #{$HOME} && tar czvf #{$BACKUP_DIR}_#{Time.now.to_i}.tgz #{$BACKUP_DIR.basename}"
system "rm -fr #{$BACKUP_DIR}" unless $debug


