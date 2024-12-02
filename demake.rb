#!/usr/bin/env ruby
#########################################################
## Recursively removes all automatically built files from
## the $ISE_ROOT directory. These files are typically make
## files created by the MPC build system, library files
## created by make and perhaps, if needed, automatically
## generated documentation files created by doxygen and rdoc.

require 'pathname'		## StdLib: Cross-platform file system capability
require 'rubygems'		## StdLib: required to make use of the following GEM packages:
require 'highline/import'	## GEM: high-level line oriented console interface

# file types to delete

filetypes = [
  '**.vcproj*','**.sln**','**GNUmakefile**',	## files created by MPC
  '**.depend**','**.o','**.so','**.so.[1-9].*'	## files created by make
]

objdirs = [
  '**.obj', '**.shobj'				## Directories created by make
]

$IGNORE_DIRS = ['.svn', 'Portal']  ## These directories will be ignored everywhere

#####################################################
def delete_only_these_files_from_dir(path, filenames)

  path.children.each do |file|

    unless file.directory? && $IGNORE_DIRS.include?(file.basename.to_s)

      if file.directory?		## If the current file is a directory
        ## recusively examine its children for
        ## possible deletion.
        delete_only_these_files_from_dir(file, filenames)
      end

      filenames.each do |type|		## for each type defined for delition
      
        if file.fnmatch?(type)		## see if the current file matches the type given
          puts "  Deleting: #{file}"
          file.delete
        end
        
      end
      
    end
  end
end

def delete_only_these_directories(path, dirnames)

  path.children.each do |file|

    unless file.directory? && $IGNORE_DIRS.include?(file.basename.to_s)

      if file.directory?

        dirnames.each do |dirname|

          if file.fnmatch?(dirname)
            puts "  Delete Dir: #{file}"
            file.rmtree			## Delete directory and everything in it
          end

        end

        delete_only_these_directories(file, dirnames) if file.exist?

      end
    end
  end
end

def usage_info(filetypes, objdirs)
  puts
  puts "Delete ISE build artifacts."
  puts
  puts "Usage: #{Pathname.new($0).basename} [--delete]"
  puts
  puts "  Command line parameters:"
  puts "    --delete ......... deletes the files without confirmation"
  puts "    --help (or -h) ... see this help text; don't delete anything"
  puts
  puts "  System Environment Variables Required:"
  puts "    ISE_ROOT ....... top directory path from which files will be deleted"
  puts
  unless Pathname.pwd == $ISE_ROOT
    puts
    say("<%= color('WARNING:', :black, :on_yellow) %> ")
    puts "  Your current working directory (CWD) is not the same as the $ISE_ROOT."
    puts
  end
  puts "    ISE_ROOT: #{$ISE_ROOT}"
  puts "    CWD:      #{Pathname.pwd}"
  puts "      Current Working Directory"
  puts
  puts "  Selected files will be deleted begging at the ISE_ROOT."
  puts "    File types are: " + filetypes.inspect
  puts "    Deleted directories are: " + objdirs.inspect
  puts "    Ignored directories are: " + $IGNORE_DIRS.inspect
  puts

end

##########
## Main ##
##########

$ISE_ROOT = ENV['ISE_ROOT'] ? Pathname.new(ENV['ISE_ROOT']) : "(not defined)"

#########################################

unless ARGV.length == 1 and ARGV[0] == '--delete'
  usage_info(filetypes, objdirs) 
end

## Validate system environment parameters

unless ENV['ISE_ROOT']
  say("<%= color('ERROR:', :white, :on_red) %> ")
  puts "The system environment variable ISE_ROOT is not defined."
  puts "       Perhaps all you need to do is source the 'setup_symbols' script."
  exit
end



unless $ISE_ROOT.directory?
  say("<%= color('ERROR:', :white, :on_red) %> ")
  puts "ISE_ROOT bad: #{$ISE_ROOT}"
  puts "       Expected it to be a valid directory."
  exit
end



if ARGV[0] == '--help' || ARGV[0] == '-h'
  exit
end

if (ARGV.length == 1 and ARGV[0] != '--delete') or (ARGV.length > 1)
  say("<%= color('ERROR:', :white, :on_red) %> ")
  puts "Unknown command line parameter(s): #{ARGV.inspect}"
  if ARGV.length > 1
    puts "       Expected 0 or 1 parameter.  Found #{ARGV.length}"
  end
  exit
end

unless Pathname.pwd.realpath == $ISE_ROOT.realpath
  puts
  say("<%= color('WARNING:', :black, :on_yellow) %> ")
  puts "Your current working directory (CWD) is not the same as the $ISE_ROOT."
  puts
  unless agree("Do you want to continue?")
    puts "... terminating."
    exit
  end
end


unless ARGV[0] == '--delete'
  unless agree("Do you want to delete the build artifacts beginning at\nISE_ROOT: #{$ISE_ROOT}?")
    puts "... terminating."
    exit
  end
end


########################################################
## Environment has been validated, now do the dirty work

delete_only_these_directories($ISE_ROOT, objdirs)
delete_only_these_files_from_dir($ISE_ROOT, filetypes)
