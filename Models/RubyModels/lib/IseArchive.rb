#####################################################################################
## IseArchive:
## Colllects the necessary and sufficient information for the extraction of an IseJob
## configuration from the IseDatabase into an IseJCL formatted file.

require 'IseJCL_Utilities'	## support utilities

#require 'IseJCL'            ## SMELL: Why is IseJCL this required?

require 'zip/zip'           ## GEM: rubyzip
require 'zip/zipfilesystem' ## GEM: rubyzip


# a singleton calls with methods to archive the major elements of the
# IseDatabase

class IseArchive
  
  ########################
  # Archive a model record
  
  def self.model (which_model,f=$stdout)
    parm_type = which_model.class.to_s
    
    if     parm_type == "Fixnum"
      begin
        a_model = Model.find(which_model)
      rescue
        a_model = nil
      end
    elsif  parm_type == "String"
      a_model = Model.find_by_name(which_model)
    else
      ERROR(["Parameters is of an unsupported class: #{parm_type}",
             "Expected to see either a model id or name."])
      return nil
    end
    
    unless a_model
      ERROR(["The specified IseModel, #{which_model}, was not found in the IseDatabase."])
      return nil
    end
    
    
    model_sym = "my_model_#{a_model.id}"
    
    indent_step = model_sym.length + " = IseModel.new(".length
    
    f.puts "#{model_sym} = IseModel.new(\"#{a_model.name}\", \"#{a_model.description}\","
    f.puts " "*indent_step + "\"#{a_model.platform.name}\","
    f.puts " "*indent_step + "\"#{a_model.location}\")"
    
    return model_sym
    
  end

  #########################################
  # Archive a complete IseJob configuration
  
  def self.job (which_job,f=$stdout)

    parm_type = which_job.class.to_s
    
    if     parm_type == "Fixnum"
      begin
        a_job = Job.find(which_job)
      rescue
        a_job = nil
      end
    elsif  parm_type == "String"
      a_job = Job.find_by_name(which_job)
    else
      ERROR(["Parameters is of an unsupported class: #{parm_type}",
             "Expected to see either a job id or name."])
      return nil
    end
    
    unless a_job
      ERROR(["The specified IseJob, #{which_job}, was not found in the IseDatabase."])
      return nil
    end
 
    job_sym = "my_job_#{a_job.id}"

    f.puts "#!/usr/bin/env ruby"
    f.puts "###############################################################"
    f.puts "###"
    f.puts "##    Job:   #{a_job.name}"
    f.puts "##    Desc:  #{a_job.description}"
    f.puts "#"
    f.puts
    f.puts "require 'IseJCL'"
    f.puts
    f.puts "#{job_sym} = IseJob.new(\"#{a_job.name}\", \"#{a_job.description}\")"
    f.puts
    f.puts "#{job_sym}.input_dir  = \"#{a_job.default_input_dir}\""
    f.puts "#{job_sym}.output_dir = \"#{a_job.default_output_dir}\""
    f.puts
    f.puts "###############################################################"
    f.puts "## Define the IseModels used by this IseJob"

    
    a_jc = JobConfig.find_all_by_job_id(a_job.id)
    
    my_m = "xyzzy"
        
    a_jc.each_index do |x|
    
      if a_jc[x].model_instance == 0
        f.puts
        my_m = self.model(a_jc[x].model_id,f)
        f.puts
        f.puts "#{my_m}.count          = #{a_jc[x].model_instance+1}"
        f.puts "#{my_m}.cmd_line_param = [\"#{a_jc[x].cmd_line_param}\"]"
        f.puts "#{my_m}.inputs         = [\"#{a_jc[x].input_file}\"]"
        f.puts "#{my_m}.drones         = [\"#{a_jc[x].node.name}\"]"
        f.puts
        f.puts "#{job_sym}.add(#{my_m})"
      else
        f.puts
        f.puts "#{my_m}.count          = #{a_jc[x].model_instance+1}"
        f.puts "#{my_m}.cmd_line_param << \"#{a_jc[x].cmd_line_param}\""
        f.puts "#{my_m}.inputs         << \"#{a_jc[x].input_file}\""
        f.puts "#{my_m}.drones         << \"#{a_jc[x].node.name}\""
      end
    
    end
    
    f.puts
    f.puts "###############################################################"
    f.puts "## Register the IseJob into the IseDatabase"
    f.puts
    f.puts "#{job_sym}.register"
    f.puts
    f.puts "## End of File"
    f.puts "##############"
    

  end ## end of def IseArchive
  
  # Archive a complete run
  
  def self.run(a_run)
    # TODO: complete the run method
    
    a_run = Run.find(a_run) if a_run.class.to_s == "Fixnum"
    a_job = a_run.job
    
    # figure out where to put this stuff
    # FIXME:  Where is the standard Archive directory?
    #
    
    archive_pathname = $ISE_RUN ? $ISE_RUN : $ISE_ROOT
    #archive_pathname = Pathname.pwd
    
    archive_pathname += "Archive"
    
    run_filename = a_job.name + "_r" + a_run.id.to_s + "_YYYYMMDDHHMMSS"  ## FIXME: append reformated created_at
    
    archive_directory_pathname = archive_pathname + run_filename
    
    # SMELL: Is this use of FileUtils.rm_rf cross-platform?
    FileUtils.rm_rf(archive_directory_pathname.to_s) if archive_directory_pathname.exist?

    archive_directory_pathname.mkpath
    
    jcl_file_path = archive_directory_pathname +         (run_filename + ".rb")   ## parens used to force string concat
    xml_file_path = archive_directory_pathname +         (run_filename + ".xml")
    sql_file_path = archive_directory_pathname +         (run_filename + ".sql")
    zip_file_path = archive_directory_pathname.dirname + (run_filename + ".zip")
    tar_file_path = archive_directory_pathname.dirname + (run_filename + ".tar")

    #########
    # job
    
    # Save the entire IseJob configuration as a JCL file
    
    jcl_out_file = File.new("#{jcl_file_path.to_s}","w")
    self.job(a_run.job.id, jcl_out_file)
    
    # Save the entire IseJob configuration as an XML file
    
    xml_out_file  = File.new("#{xml_file_path.to_s}","w")
    
    my_jc = JobConfig.find_all_by_job_id(a_job.id)
    
    my_jc.each do | a_jc |
    
      xml_out_file.puts a_jc.model.to_xml
      xml_out_file.puts a_jc.to_xml
    
    end
    
    xml_out_file.puts a_job.to_xml

=begin    
    #######
    # peer
    
    my_peers = RunPeer.find_all_by_run_id(a_run.id)
    
    xml_out_file.puts my_peers.to_xml
=end    
    
    #########
    # run
    
    xml_out_file.puts a_run.to_xml
    
    ############
    # input_dir
    
    input_dir = Pathname.new(a_run.input_dir)
    # zip into archive_directory_pathname
    
    ##############
    # output_dir
    
    output_dir = Pathname.new(a_run.output_dir)
    # zip into archive_directory_pathname
    
    #######
    # guid
    # may have to invoke a system routine to dump the database
    # as sql to the sql_file_path.  This will also need to be cross-platform
    # SMELL: does not test RUBY_PLATFORM to see what kind of box it is run on
    
    case $GUID_CONFIG['adapter']    
      when "mysql"
        the_params  = " --host=#{$GUID_CONFIG['host']}"     ## Which machine has the RDBMS?
        the_params += " --user=#{$GUID_CONFIG['username']}" ## user account
        the_params += " --add-drop-database"    ## add drop in front of create database
        the_params += " --opt"                  ## optimize for fast dump as restore; includes
                                                ## --add-drop-table --add-locks --create-options
                                                ## --disable-keys --extended-insert --lock-tables
                                                ## --quick --set-charset.
#        the_params += " --xml"                  ## Output file is well formed XML instead of SQL
        the_cmd     = "mysqldump #{the_params} #{a_run.guid} --result-file=#{sql_file_path.to_s}"
      when "posgresql"
        the_cmd = nil
      when "sqlite3"
        the_cmd = nil
      else
        ERROR(["The backend RDBMS (#{$GUID_CONFIG['adapter']}) used for the GUID database is not supported."])
        the_cmd = nil
    end
    
    puts the_cmd if $DEBUG
    system the_cmd if the_cmd
    
    ##########################################
    # zip the archive_directory_pathname
    # Can either do this within ruby or invoke a system shell
    # and use a platform appropriated command line utility
    
    if RUBY_PLATFORM.include?("linux")
      the_cmd  = "tar cf #{tar_file_path.to_s} #{archive_directory_pathname.to_s}; "
      the_cmd += "gzip #{tar_file_path.to_s}"
    elsif platfprm.include?("mswin32")
      the_cmd = "zip #{archive_directory_pathname.to_s}"
    else
      ERROR(["This platform (#{RUBY_PLATFORM}) is not supported."])
      the_cmd = nil
    end
    
    system the_cmd if the_cmd
  
  end
  
  # Archive peers associated with a run
  
  def self.peer
    # TODO: complete the peer method
  end
  
  # Archive the GUID database associated with a run
  
  def self.guid
    # TODO: complete the guid method
  end
  
  # Archive the output directory associated with a run
  
  def self.output_dir
    # TODO: complete the output_dir method
  end
  
  # Archive the input directory associated with a run
  
  def self.input_dir
    # TODO: complete the input_dir method
  end
  

end ## end of class IseArchive

