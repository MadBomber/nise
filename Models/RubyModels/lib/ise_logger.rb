=begin

  TODO: replace all uses of the IseLogger class with those
        of Yell - Your Extensible Logging Library

=end

##################################################################
###
##  File: ise_logger.rb
##  Desc: define the common ISE logging environment
##        Makes use of ENV['ISE_LOG']
##          if $ISE_LOG == 'syslog' then use the system log
##          otherwise assume that its a file to be appended to
##          if not exist? then use default $ISE_ROOT/output/ise.log
##        Makes use of ENV['ISE_LOG_LEVEL']
##          if not present defaults to ERROR

require 'pathname'
require 'IseLogger'

# over-ride the class to expose ident
class Syslogger
  attr_accessor :ident
end

        
module ISE

  PREFIX = "ISE"

  if defined?($OPTIONS)
    unless $OPTIONS[:model_name]
      APP_NAME = "#{PREFIX}:#{$OPTIONS[:model_name]}"
    else
      APP_NAME = PREFIX
    end
  else
    APP_NAME = PREFIX
  end

  DEFAULT_ISELOG        = Pathname.new(ENV['ISE_ROOT']) + "output" + "ise.log"
  DEFAULT_ISELOG_LEVEL  = 'ERROR'
  VALID_LOG_LEVELS      = ['DEBUG','INFO','WARN','ERROR','FATAL','UNKNOWN']

  UNKNOWN = IseLogger::UNKNOWN  # catch all -- used if nothing else applies
  FATAL   = IseLogger::FATAL    # an unrecoverable error that results in a program crash
  ERROR   = IseLogger::ERROR    #	a recoverable error condition
  WARN    = IseLogger::WARN     #	a warning
  INFO    = IseLogger::INFO     #	generic (useful) information about system operation
  DEBUG   = IseLogger::DEBUG    #	low-level information for developers


  class Log
    @@iselog  = nil
    @@run_id  = 0
    
    # Initialize an iselog; use the ENV['ISE_LOG'] as default
    # allow user to specify a file path different from the default
    def initialize(log_file_name=nil)

      $ISE_LOG        = ENV['ISE_LOG'] || ""
      $ISE_LOG_LEVEL  = (ENV['ISE_LOG_LEVEL'] || DEFAULT_ISELOG_LEVEL).upcase

      ISE::Log.close unless @@iselog.nil?
    
      $ISE_LOG = log_file_name unless log_file_name.nil?

      if 'IO' == $ISE_LOG.class.to_s
        # user has passed in $stdout or $stder
        
      elsif 'File' == $ISE_LOG.class.to_s
        # user has passed in his own file pointer
        
      elsif 'stdout' == $ISE_LOG.downcase
        $ISE_LOG = $stdout
        
      elsif 'stderr' == $ISE_LOG.downcase
        $ISE_LOG = $stderr

      elsif 'syslog' == $ISE_LOG.downcase
        require 'syslogger'
        @@iselog = Syslogger.new(APP_NAME, Syslog::LOG_PID | Syslog::LOG_CONS | Syslog::LOG_NDELAY, Syslog::LOG_SYSLOG)
        
      elsif $ISE_LOG.empty?
        $ISE_LOG = DEFAULT_ISELOG
        
      else
        $ISE_LOG = Pathname.new $ISE_LOG

      end

      if 'Pathname' == $ISE_LOG.class.to_s
        log_file          = File.open($ISE_LOG.to_s, File::WRONLY|File::APPEND|File::CREAT)
        @@iselog          = IseLogger.new(log_file, 5, 1024000) # keep 5 old logs; change at 1Gb
        @@iselog.progname = APP_NAME
        
      elsif 'IO' == $ISE_LOG.class.to_s
        @@iselog          = IseLogger.new($ISE_LOG) # goint to stderr or stdout
        @@iselog.progname = APP_NAME
      
      elsif 'File' == $ISE_LOG.class.to_s
        @@iselog          = IseLogger.new($ISE_LOG, 5, 1024000) # keep 5 old logs; change at 1Gb
        @@iselog.progname = APP_NAME

      end

      unless VALID_LOG_LEVELS.include?($ISE_LOG_LEVEL)
        $ISE_LOG_LEVEL = DEFAULT_ISELOG_LEVEL
      end

      @@iselog.level = eval("IseLogger::#{$ISE_LOG_LEVEL}")
      
      #@@iselog.debug "started log"

    end ## end of def initialize(log_file_name=nil)

    # pass method calls onto the iselog
    # NOTE: only supports 1 argument does not support the block construct
    def self.method_missing(method_sym, a_string=nil)
      method_name = method_sym.id2name
      Log.new if @@iselog.nil?
      begin
        @@iselog.send(method_name, a_string)
      rescue
        self.error "Unknown method called on ISE::Log -=> #{method_name} with: #{a_string}"
      end
    end

    # close the current iselog
    def self.close
      Log.new if @@iselog.nil?
      #@@iselog.debug "closing log"
      
      if 'Pathname' == $ISE_LOG.class.to_s or 'File' == $ISE_LOG.class.to_s
        @@iselog.close 
      end

    end
    
    # expose the actual iselog object
    def self.iselog
      @@iselog
    end
    
    # Determines if there is already an active log
    def self.active?
      return(not @@iselog.nil?)
    end
    
    # Assign a logging level to the iselog
    def self.level=(a_level=Logger::ERROR)
      @@iselog.level = a_level if (IseLogger::DEBUG .. IseLogger::UNKNOWN).include?(a_level)
    end

    # Retrieve the current logging level for the iselog
    def self.level
      @@iselog.level
    end


    # Returns +true+ iff the current severity level allows for the printing of
    # +DEBUG+ messages.
    def self.debug?; @@iselog.level <= DEBUG; end

    # Returns +true+ iff the current severity level allows for the printing of
    # +INFO+ messages.
    def self.info?; @@iselog.level <= INFO; end

    # Returns +true+ iff the current severity level allows for the printing of
    # +WARN+ messages.
    def self.warn?; @@iselog.level <= WARN; end

    # Returns +true+ iff the current severity level allows for the printing of
    # +ERROR+ messages.
    def self.error?; @@iselog.level <= ERROR; end

    # Returns +true+ iff the current severity level allows for the printing of
    # +FATAL+ messages.
    def self.fatal?; @@iselog.level <= FATAL; end

    # Returns +true+ iff the current severity level allows for the printing of
    # +UNKNOWN+ messages.
    def self.unknown?; true; end


    
    # Retrieve the current program name used to mark the log
    def self.progname
      if 'Syslogger' == @@iselog.class.to_s
        @@iselog.ident
      else
        @@iselog.progname
      end
    end
        
    # Set the current program name (ident) to something
    def self.progname=(a_string)
      if 'String' == a_string.class.to_s
        
        if 'ISE:' == a_string[0,4]
          a_string = a_string[4, a_string.length]
        end
        
        prefix_str = ISE::PREFIX + " "
        
        if 'Syslogger' == @@iselog.class.to_s
          @@iselog.ident    = prefix_str + a_string
        else
          @@iselog.progname = prefix_str + a_string
        end
        
        self.run_id= $run_record.id unless $run_record.nil?
        
      else
        @@iselog.error "Attempt to set progname/ident for logger to non-string type: #{a_string.class}"
      end
    end

    ##########################################################
    ## Insert the run_id into the progname/ident
    def self.run_id=(my_run_id)
    
      if 0 == @@run_id
        old_str = ISE::PREFIX
        new_str = "#{ISE::PREFIX}[run:#{my_run_id}]"      
      else
        old_str = "[run:#{@@run_id}]"
        new_str = "[run:#{my_run_id}]"
      end

      if 'Syslogger' == @@iselog.class.to_s
        @@iselog.ident.gsub!(old_str, new_str)
      else
        @@iselog.progname.gsub!(old_str, new_str)
      end
      
      @@run_id = my_run_id
      
    end


    # alias the class methods to support the Syslogger equivalent attributes
    class << self
      alias ident   progname
      alias ident=  progname=
    end

  end ## end of class Log

end ## end of module ISE
