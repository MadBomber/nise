#!/usr/bin/env ruby
#############################################################
###
##  File: genise.rb
##  Desc: Generate ISE components
##
## TODO: Replace this mess with thor generators like Rails 3 uses.
#


require 'rubygems'
require 'templater'
require 'systemu'
require 'pathname_mods'
require 'string_mods'
require 'debug_me'
require 'pp'
require 'ap'

# puts "The ARGV array is:"
# ap ARGV
# puts



#######################################################
## Moding the Templater::Generator class
module Templater

  class Generator
    ######################################################
    ## Define my own stuff
    class << self
    
      # Search a directory for templates and files and add them to this generator. Any file
      # whose extension matches one of those provided in the template_extensions parameter
      # is considered a template and will be rendered with ERB, all others are considered
      # normal files and are simply copied.
      #
      # A hash of options can be passed which will be assigned to each file and template.
      # All of these options are matched against the options passed to the generator.
      #
      # === Parameters
      # source<String>:: The directory to search in, relative to the source_root, if omitted
      #     the source root itself is searched.
      # template_destination<Array[String]>:: A list of extensions. If a file has one of these
      #     extensions, it is considered a template and will be rendered with ERB.
      # options<Hash{Symbol=>Object}>:: A list of options.
      def init_project(
              dir       = nil,
              dest_dir  = nil,
              template_extensions = %w(rake mpc h cpp inc ini rb haml sass css js erb html xml yml txt dot sh s bat ps1 setup_symbols Gemfile Rakefile TODO LICENSE README),
              options={})
             
        if 'Symbol' == dest_dir.class.to_s
          x = nil
          @arguments.each_index do |y|
            if @arguments[y].name == dest_dir
              x = y
              break
            end
          end
          dest_dir = ARGV[x+1]
          project_id   = ARGV[x+1]       # FIXME: Should have access to the parameters from the cmd line
          project_name = ARGV[x+2]       # FIXME: Should have access to the parameters from the cmd line
          project_desc = ARGV[x+3]       # FIXME: Should have access to the parameters from the cmd line
        end
        

        ::Dir[::File.join(source_root, dir.to_s, '**/*')].each do |action|
        
          unless ::File.directory?(action)
          
            action = action.sub("#{source_root}/", '')
            # action is now the file path without the source_root

            dest_action = action.sub("#{dir}/", "#{dest_dir}/")
            
            unless project_id.nil?
            
              dest_action['project_id_mwc.txt'] = "#{project_id.downcase}.mwc" if dest_action.include?('project_id_mwc')

              dest_action['project_id'] = "#{project_id.downcase}" if dest_action.include?('project_id')
              
              if '.dot' == dest_action[-4,4]    # turn *.dot files into .* files
                aa = dest_action.split('/')
                base_filename = aa.last
                dest_action[base_filename] = ".#{base_filename}"
                dest_action['.dot'] = ''
              end
            
            end

            if template_extensions.include?(::File.extname(action.sub(/\.%.+%$/,''))[1..-1]) or template_extensions.include?(::File.basename(action))
              template(action.downcase.gsub(/[^a-z0-9]+/, '_').to_sym, action, dest_action)
            else
              file(action.downcase.gsub(/[^a-z0-9]+/, '_').to_sym, action, dest_action) unless '~' == action[-1,1] # ignore the backup files
            end
          
          else # dealing with a directory
          
            # puts "dealing with a directory: #{action} to #{dest_action}"
            
          end # unless ::File.directory?(action)
          
        end # ::Dir[::File.join(source_root, dir.to_s, '**/*')].each do |action|

      end # def init_project
      


    
      # Search a directory for templates and files and add them to this generator. Any file
      # whose extension matches one of those provided in the template_extensions parameter
      # is considered a template and will be rendered with ERB, all others are considered
      # normal files and are simply copied.
      #
      # A hash of options can be passed which will be assigned to each file and template.
      # All of these options are matched against the options passed to the generator.
      #
      # === Parameters
      # source<String>:: The directory to search in, relative to the source_root, if omitted
      #     the source root itself is searched.
      # template_destination<Array[String]>:: A list of extensions. If a file has one of these
      #     extensions, it is considered a template and will be rendered with ERB.
      # options<Hash{Symbol=>Object}>:: A list of options.
      def init_model(
              dir       = nil,
              dest_dir  = nil,
              template_extensions = %w(mpc h cpp inc ini rb css js erb html yml txt sh s bat ps1 setup_symbols Gemfile Rakefile TODO LICENSE README),
              options={})
             
        if 'Symbol' == dest_dir.class.to_s
          x = nil
          @arguments.each_index do |y|
            if @arguments[y].name == dest_dir
              x = y
              break
            end
          end
          dest_dir = ARGV[x+1]
        end
        
        model_name = ARGV[1]
        
        dest_dir = dest_dir.to_camelcase unless dest_dir.nil?

        ::Dir[::File.join(source_root, dir.to_s, '**/*')].each do |action|
        
          unless ::File.directory?(action)
          
            action = action.sub("#{source_root}/", '')
            # action is now the file path without the source_root

            dest_action = action.sub("#{dir}/", "#{dest_dir}/")
            dest_action['model_name'] = "#{model_name}" if dest_action.include? 'model_name'
            
            dest_action['app_mpc.txt'] = 'app.mpc' if dest_action.include?('app_mpc')

            if template_extensions.include?(::File.extname(action.sub(/\.%.+%$/,''))[1..-1]) or template_extensions.include?(::File.basename(action))
              template(action.downcase.gsub(/[^a-z0-9]+/, '_').to_sym, action, dest_action) # do |t|
              #  t.source      = action
              #  dest_action['model_name'] = "#{model_name}"
              #  t.destination = dest_action
              #end
            else
              file(action.downcase.gsub(/[^a-z0-9]+/, '_').to_sym, action, dest_action) unless '~' == action[-1,1] # ignore the backup files
            end
          
          else # dealing with a directory
          
            puts "dealing with a directory: #{action} to #{dest_action}"
            
          end # unless ::File.directory?(action)
          
        end # ::Dir[::File.join(source_root, dir.to_s, '**/*')].each do |action|
        
      end # def init_model

      
    end # class << self
  end # class Generator
end # module Templater





module GenISE

  VERSION = '0.1'

  extend Templater::Manifold

  desc "Component Generators for ISE"

  ############################################################################
  def self.tbd(*args)
    puts
    puts "###################################################"
    puts "## This genise capability is under construction. ##"
    puts "## Results may not be usable as generated.       ##"
    puts "###################################################"
    puts
    puts "args -=>"
    ap args
    puts
    puts "ARGV -=>"
    ap ARGV
    puts
  end # end of def self.tbd(*args)

  ############################################################################
  ## Find the location of a directory
  ## TODO: Remove assumption that the cwd is above the target directory.
  ##       The target directory could be up and ober; so how far up should be checked?
  ##       If the project_id is given, then attempt to use the XTZZT_ROOT environment
  ##       variable to locate the target directory.
  def self.find(a_dir)
    a,b,c = systemu("find . -name '#{a_dir}'")  # FIXME: This will not work on MS Windows
    if b.empty?
      b = Dir.pwd
    else
      # FIXME: b (stdout) could return several hits
      #        use b.split to get an array of hits
      #        Howerver, can't just use the first one because find
      #        works on inodes, not depth or breath.
      b = b.split
      if b.length > 1
        puts
        puts "ERROR: Found several '#{a_dir}' directories.  Don't know which one to use."
        puts "       cd into the one you want, then try the genise command again."
        puts "       The directories found are:"
        b.each do |bb|
          puts "          #{bb}"
        end
        puts
        exit -1
      end
      b = Pathname.new(b[0].chomp).realpath.to_s
    end
    return b
  end # end of def self.find


  ######################################################
  class ProjectGen < Templater::Generator
    # TODO: Complete the ProjectGen
    
    desc <<-DESC
      Generate an IseProject directory structure suitable for use with subversion.
      
        Specific Usage: genise project [options] project_id project_name "project_desc"
      
      project_id      short, unique identifier (an acronym works well)
                      Examples: AADSE, MicroGrid, VRSIL_Tools, Experiments
      
      project_name    short, unique descriptive name without special characters other than underscoe
                      Example:  aad_synthetic_environment
      
      "project_desc"  short, one line description of the project surrounded by double quotes
                      Example: "Advanced Air Defense Synthetic Environment (AADSE)"
    DESC
    
    argument( 0, :project_id,    :required => true, :desc => "The project's unique ID usually an acronym. Example: \"XYZZY\"")
    argument( 1, :project_name,  :required => true, :desc => "The project's unique name in snake_case format.  Example: \"external_yz_zy_inverter\"")
    argument( 2, :project_desc,  :required => true, :desc => "The project's single line description. Example: \"External YZ and ZY inverter (XYZZY)\"")

    def self.source_root
      File.join(ENV['ISE_ROOT'], 'bin/cm_tools/templates')
    end
        
    destination_root = Dir.pwd

    init_project( 'ise_project_svn', :project_id )

    # invoke JobGen with some standard parameters to create the first job
    # NOTE: one of the things that we would like to do AFTER the project directory
    #       is established is to create the first IseJob using the project_name and the
    #       project_desc as the job_name and job_desc.  The invoke method allows the mixin
    #       of other generators HOWEVER there is no way of knowing when the mixin will be
    #       executed.  No matter the order of the code either before or after init_project
    #       the invoked job generator puts its file at CWD and not the Jobs directory within
    #       project tree.
    # invoke :job do |j|
    #   j.new(File.join(Dir.pwd, "#{project_id}/trunk/Jobs"), options, project_name, project_desc)
    # end
    

  end # class ProjectGen < Templater::Generator

  #############################################################
  class CppModelGen < Templater::Generator
    # TODO: Complete the CppModelGen

    desc <<-DESC
      Generate a C++ IseModel
      
        Specific Usage: genise cpp_model [options] model_name "model_desc" [project_id] 
      
      model_name   short, unique descriptive name without special characters other than underscoe
                   Example:  aad_synthetic_environment
      
      "model_desc" short, one line description of the model surrounded by double quotes
                   Example: "Advanced Air Defense Synthetic Environment (AADSE)"
      
      project_id   short, unique identifier (an acronym works well)
                   Examples: AADSE, MicroGrid, VRSIL_Tools, Experiments

    DESC

    argument( 0, :model_name,  :required => true, :desc => "The ruby model's unique name in snake_case format.  Example: \"external_yz_zy_inverter\"")
    argument( 1, :model_desc,  :required => true, :desc => "The ruby model's single line description. Example: \"External YZ and ZY inverter (XYZZY)\"")
    argument( 2, :project_id,                     :desc => "The project's unique ID usually an acronym. Example: \"XYZZY\"")


    def self.source_root
      File.join(ENV['ISE_ROOT'], 'bin/cm_tools/templates/ise_cpp_model')
    end
            
    init_model( 'ModelName', :model_name )    
    
    def initialize(*arg)
      super
      @destination_root = GenISE::find('Models')
    end

  end # class CppModelGen < Templater::Generator
  
  #############################################################
  class RubyModelGen < Templater::Generator
    # TODO: Complete the RubyModelGen

    desc <<-DESC
      Generate an IseRubyModel
      
        Specific Usage: genise ruby_model [options] model_name "model_desc" [project_id] 
      
      model_name   short, unique descriptive name without special characters other than underscoe
                   Example:  aad_synthetic_environment
      
      "model_desc" short, one line description of the model surrounded by double quotes
                   Example: "Advanced Air Defense Synthetic Environment (AADSE)"
      
      project_id   short, unique identifier (an acronym works well)
                   Examples: AADSE, MicroGrid, VRSIL_Tools, Experiments

    DESC

    argument( 0, :model_name,  :required => true, :desc => "The ruby model's unique name in snake_case format.  Example: \"external_yz_zy_inverter\"")
    argument( 1, :model_desc,  :required => true, :desc => "The ruby model's single line description. Example: \"External YZ and ZY inverter (XYZZY)\"")
    argument( 2, :project_id,                     :desc => "The project's unique ID usually an acronym. Example: \"XYZZY\"")


    def self.source_root
      File.join(ENV['ISE_ROOT'], 'bin/cm_tools/templates/ise_ruby_model')
    end
    
    
    # NOTE: The rdoc for template is wrong, this works:
    template :model do |t|
      t.source      = 'model_name.rb'
      t.destination = "#{model_name}.rb"
    end
    
#    template :test_model do |t|
#      t.source      = 'test_model_name.rb'
#      t.destination = "test_#{model_name}.rb"
#    end
    
    init_model( 'ModelName', :model_name )    
    
    def initialize(*arg)
      super
      @destination_root = GenISE::find('RubyModels')
    end


  end # class RubyModelGen < Templater::Generator
  
  #############################################################
  class MessageGen < Templater::Generator
    # TODO: Complete the MessageGen

    desc <<-DESC
      Generate an IseMessage skeleton for both C++ and Ruby
      
        Specific Usage: genise message_name [options] message_name "message_desc" [project_id] 
      
      message_name     short, unique descriptive name without special characters other than underscoe
                       Example:  position_truth
      
      "message_desc"   short, one line description of the message surrounded by double quotes
                       Example: "The true position of an object"
      
      project_id       short, unique identifier (an acronym works well)
                       Examples: AADSE, MicroGrid, VRSIL_Tools, Experiments

    DESC

    argument( 0, :message_name,  :required => true, :desc => "The message_name's unique name in snake_case format.  Example: \"position_truth\"")
    argument( 1, :message_desc,  :required => true, :desc => "The message_name's single line description. Example: \"The true position of an object\"")
    argument( 2, :project_id,                       :desc => "The project's unique ID usually an acronym. Example: \"AADSE\"")


    def self.source_root
      File.join(ENV['ISE_ROOT'], 'bin/cm_tools/templates/ise_message')
    end
    
    # NOTE: The rdoc for template is wrong, this works:
    template :message do |t|
      t.source      = 'MessageName.rb'
      t.destination = "#{message_name.to_camelcase}.rb"
    end
    
    template :message do |t|
      t.source      = 'MessageName.h'
      t.destination = "#{message_name.to_camelcase}.h"
    end
    
    def initialize(*arg)
      super
      @destination_root = GenISE::find('Messages')
    end


  end # class MessageGen < Templater::Generator
  
  #############################################################
  class JobGen < Templater::Generator
    # TODO: Complete the JobGen

    desc <<-DESC
      Generate a skeleton for an IseJob
      
        Specific Usage: genise job [options] job_name "job_desc" [project_id] 
      
      job_name    short, unique descriptive name without special characters other than underscoe
                  Example:  aad_synthetic_environment
      
      "job_desc"  short, one line description of the job surrounded by double quotes
                  Example: "Advanced Air Defense Synthetic Environment (AADSE)"
      
      project_id  short, unique identifier (an acronym works well)
                  Examples: AADSE, MicroGrid, VRSIL_Tools, Experiments

    DESC

    argument( 0, :job_name,  :required => true, :desc => "The job's unique name in snake_case format.  Example: \"external_yz_zy_inverter\"")
    argument( 1, :job_desc,  :required => true, :desc => "The job's single line description. Example: \"External YZ and ZY inverter (XYZZY)\"")
    argument( 2, :project_id,                   :desc => "The project's unique ID usually an acronym. Example: \"XYZZY\"")


    def self.source_root
      File.join(ENV['ISE_ROOT'], 'bin/cm_tools/templates/ise_job')
    end
    
    def chmod(action)
      File.chmod(0777, action.destination)
    end
   
    # NOTE: The rdoc for template is wrong, this works:
    template :job, :after => :chmod do |t|
      t.source      = 'job_name.rb'
      dest_action   = job_name
      unless dest_action.include? '_job'
        dest_action = dest_action + '_job'
      end
      t.destination = "#{dest_action}.rb"
    end
    

    ####################
    def initialize(*arg)
      super
      @destination_root = GenISE::find('Jobs')
    end
    

  end ## class JobGen < Templater::Generator
  
  #############################################################
  class ScenarioGen < Templater::Generator
    # TODO: Complete the ScenarioGen

    desc <<-DESC
      Generate a skeleton for an IseScenario
      
        Specific Usage: genise scenario [options] scenario_name "scenario_desc" [project_id] 
      
      scenario_name   short, unique descriptive name without special characters other than underscoe
                      Example:  aad_synthetic_environment
      
      "scenario_desc" short, one line description of the scenario surrounded by double quotes
                      Example: "Advanced Air Defense Synthetic Environment (AADSE)"
      
      project_id      short, unique identifier (an acronym works well)
                      Examples: AADSE, MicroGrid, VRSIL_Tools, Experiments

    DESC

    argument( 0, :scenario_name,  :required => true, :desc => "The scenario's unique name in snake_case format.  Example: \"external_yz_zy_inverter\"")
    argument( 1, :scenario_desc,  :required => true, :desc => "The scenario's single line description. Example: \"External YZ and ZY inverter (XYZZY)\"")
    argument( 2, :project_id,                   :desc => "The project's unique ID usually an acronym. Example: \"XYZZY\"")


    def self.source_root
      File.join(ENV['ISE_ROOT'], 'bin/cm_tools/templates/ise_scenario')
    end
    
    # TODO: Change destination_root to the Jobs directory
    destination_root = Dir.pwd
    
    # NOTE: The rdoc for template is wrong, this works:
    template :job do |t|
      t.source      = 'scenario_name.rb'
      dest_action   = scenario_name
      unless dest_action.include? '_scenario'
        dest_action = dest_action + '_scenario'
      end
      t.destination = "#{dest_action}.rb"
    end
    
    
    
        
    def initialize(*arg)
      super
      GenISE::tbd self.class.to_s
    end


  end # class ScenarioGen < Templater::GeneratorS
  
  add :project,     ProjectGen
  add :cpp_model,   CppModelGen
  add :ruby_model,  RubyModelGen
  add :message,     MessageGen
  add :job,         JobGen
  add :scenario,    ScenarioGen



end ## module GenIse

# registers manifold with command line interface
GenISE.run_cli Dir.pwd, 'genise', GenISE::VERSION, ARGV

