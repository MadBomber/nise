#####################################################
###
##  File:  logger_junk.rb
##  Desc:  Many logging funtions
#

##########################
def simple_error error_msg
  $stderr.puts
  $stderr.puts "\t#{error_msg}"
  $stderr.puts
end

#########################
def trace_error error_msg

  simple_error error_msg

  c = caller

  # remove error helpers
  c.delete_at 0 while c[0][/trace_warning|internal_error|fatal_error|die/]

  $stderr.puts "\tSTACK TRACE:"
  c.each {|cc| $stderr.puts "\t\tfrom #{cc}"}
  $stderr.puts
end

##############################
def simple_warning warning_msg
  simple_error "WARNING: #{warning_msg}"
end

#############################
def trace_warning warning_msg
  trace_error "WARNING: #{warning_msg}"
end

############################
def internal_error error_msg
  trace_error "INTERNAL SYSTEM ERROR: #{error_msg}"
end


###################################
def fatal_error error_msg
  trace_error "FATAL ERROR: #{error_msg}"
  exit(-1)
end

alias :die :fatal_error

###################################
#def die error_msg
#  trace_error "FATAL ERROR: #{error_msg}"
#  exit(-1)
#end

###########################################################
def log_this(thing)
  debug_me("Logged: #{thing}")
  $stdout.flush
end


##################
def log_event(msg)
  log_this "EVENT: #{@label}: #{msg}"
end


###########################
def verbose_out verbose_msg
  if $verbose
    target = $stdout
    $stdout = STDOUT
    $stdout.puts verbose_msg
    $stdout = target
  end
end

###########################
def log_verbose verbose_msg
  log_this verbose_msg if $verbose
end ## end of log_verbose verbose_msg



#######################
def log_debug debug_msg
  log_this "DEBUG: #{debug_msg}" if $debug
end ## end of debug_out debug_msg


#######################
def log_error error_msg
  log_this "\tERROR: #{error_msg}"
  simple_error "ERROR: #{error_msg}" if $stdout != STDOUT
end ## end of error_out error_msg


##################
def log_warning warning_msg
  log_this "\tWARNING: #{warning_msg}"
  simple_warning warning_msg if $stdout != STDOUT
end




