##################################################################
###
##  File: bundle.rake
##  Desc: Defines the tasks used to ensure that all required gems
##        have been installed
#

require 'systemu'   # used to support external scripting

namespace :bundle do

  desc "Install missing gems"
  task :install do
    a,b,c = systemu( "bundle check" )
    if b.include?('could not be satisfied')
      a,b,c = systemu( "bundle install" )
      if b.include?('31mCould not find gem')
        puts b
        puts c
        raise 'gem not found in standard sources' 
      end
    end
  end

end

