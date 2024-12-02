############################################################
###
##  File: Rakefile
##  Desc: Top-level rake file for the ISE project
##        This file provides the consistent set of tasks for
##        with a generic project.
##
##  CruiseControl Integration:
##
##    CC looks for a 'build' task in the following order
##        :cruise, :test, :default
##
##  The :default task is executed when rake is executed without
##  command line parameters.
#

$debug_rakefile = true

require 'debug_me'


debug_me

#require 'rake'            # GEM: Defines the rake DSL
require 'rake/testtask'   # GEM: Defines common ruby testing tasks
#require 'rake/rdoctask'   # GEM: Defines common ruby documentation tasks
#require 'rake/hooks'      # GEM: Allows use of after/before hooks on tasks

#require 'rtfm/tasks'      # GEM: Used to generate man pages

#require 'ci/reporter/rake/test_unit'  # Supports Hudson integration

require 'ae'              # GEM: Adds some assert sugar to TestUnit

require 'pathname'        # STDLIB: cross-platform path/file names

# Assume that the system environment variable for the top-level of this
# project has been set.  Create an equivalent Ruby global constant.

$ISE_ROOT = Pathname.new ENV['ISE_ROOT']

# Identify all the areas where project-level task files might reside.
# Note that no web applications directories are identified.  They
# typically have their own Rakefile that are web-app specific.

task_dirs = %W{
  tasks
  lib/tasks
  Models/tasks
  Models/RubyModels/lib/tasks
  WebApp/Portal/lib/tasks
}



# Identify all the areas where project-level test files might reside.
# Note that no web applications directories are identified.  They
# typically have their own Rakefile that are web-app specific.

test_dirs = %W{
  test
  lib/test
  Models/test
  Models/RubyModels/lib/test
  Models/RubyModels/lib/test/unit
}




########################################################
## Dynamically Load All task files

task_dirs.each do |td|

  task_dir_path = $ISE_ROOT + td
  
  if task_dir_path.exist?
  
    if task_dir_path.directory?
    
      puts "Reviewing #{task_dir_path} for rake task files ..." if $debug_rakefile
      
      task_dir_path.children.each do |c|
        if '.rake' == c.extname
          puts "  Loading #{c.basename} ..." if $debug_rakefile
          load c.to_s
        end
      end
      
    end # end of if task_dir_path.directory?
    
  end # end of if task_dir_path.exist?
  
end # end of task_dirs.each do |td|


########################################################
## Dynamically create the test task for all test files


test_dirs.each do |td|

  test_dir_path = $ISE_ROOT + td
  
  if test_dir_path.exist?
  
    if test_dir_path.directory?
    
      puts "Reviewing #{td} for test files ..." if $debug_rakefile

      Rake::TestTask.new do |t|
        t.libs << test_dir_path.to_s
        t.test_files = FileList["#{test_dir_path}/test*.rb", "#{test_dir_path}/*_test.rb"]        
        t.verbose = true
      end
      
    end # end of if test_dir_path.dir?
    
  end # end of if test_dir_path.exist?
  
end # end of test_dirs.each do |td|






