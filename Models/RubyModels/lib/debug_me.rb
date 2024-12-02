##################################################
## debug_me.rb
## A tool to print the labeled value of variables.
## Works with local, instance and class variables.
## Example usage:
=begin
  debug_me      # Prints only the header banner consisting of tag, method name, file name and line number
  debug_me('INFO')  # Also prints only the header but with a different tag
  debug_me {}       # prints the default header and __ALL__ variables
  debug_me {:just_this_variable}  # prints the default header and the value of only one specific variable
  debug_me { [:this_one, :that_one, :that_other_one] } # prints default header and three specific variables
  debug_me(:header => faluse) {} # disables the printing of the header; prints all variables
  debug_me(:tag => 'MyTag', :header => false) {}  # disables header, sets different tag, prints all variables
  debug_me('=== LOOK ===') {}  # changes the tag and prints all variables with a header line
  debug_me('=== LOOK ===') {:@foo}   # changes the tag, prints a header line and a specific instance variable
  debug_me('=== LOOK ===') {:@@foo}  # changes the tag, prints a header line and a specific class variable
  debug_me(:ivar => false, :cvar => false) {} # print only the local variables with the default tag and a header line
  debug_me(:file=>'StringOut')  # returns stuff as a string instead of puts to a file stream
  debug_me(:pry=>true){}  # opens a pry console within the current binding
=end

require 'rubygems' unless defined?(Gem)
require 'pp'
require 'ap'

def debug_me( options={}, &block )
  
  return($debug_me) if defined?( $debug_me ) and :off == $debug_me
  
  default_options = { :tag    => 'DEBUG:',  # A tag to prepend to each output line
                      :time   => true,      # Include a time-stamp in front of the tag
                      :header => true,      # Print a header string before printing the variables
                      :ivar   => true,      # Include instance variables in the output
                      :cvar   => true,      # Include class variables in the output
                      :trace  => false,
                      :file   => $stdout,   # The output file
                      :pry    => false      # open a 'pry session'
                    }
                    
  if 'Hash' == options.class.to_s
    options = default_options.merge(options)
  else
    options = default_options.merge({:tag => options})
  end
  
  f = options[:file]
  
  if 'StringOut' == f
    f = StringOut.new
  end
  
  
  s   = ""
  s   += "#{sprintf('%010.6f', Time.now.to_f)} " if options[:time] 
  s   += "  #{options[:tag]}"
  wf  = caller    # where_from under 1.8.6 its a stack trace array under 1.8.7 is a string
  wf = wf[0] if 'Array' == wf.class.to_s
  f.puts "#{s}   Source: #{wf}" if options[:header]

  
  if options[:pry]
    if block_given?
    require 'pry'
      block.binding.pry
    else
      f.puts "WARNING: to use the :pry option you must provide a block like this:"
      f.puts "         debug_me(:pry=>true){}"
    end
  end

  if block_given?
  
    block_value = [ block.call ].flatten.compact
    
    if block_value.empty?
      block_value = eval('local_variables', block.binding)
      block_value += [ eval('instance_variables', block.binding) ]  if options[:ivar]
      block_value += [ self.class.send('class_variables') ] if options[:cvar]
      block_value = block_value.flatten.compact
      puts "all: " + block_value.inspect
    else
      block_value.map! { |v| v.to_s }
    end
    
    block_value.each do |v|
      ev = eval(v.to_s, block.binding)
      if 'OpenStruct' == ev.class.to_s
        ev = ev.marshal_dump
      end
      f.puts "#{s} #{v} -=> #{ev.pretty_inspect}"
    end
    
  end ## if block_given?
  
  if options[:trace]
    caller.each {|a_line| f.puts "#{s} TRACE -=> #{a_line}" }
  end
  
  f.flush 
  
  if options[:pry]
    require 'pry'
    if block_given?
      block.binding.pry
    else
      binding.pry
    end
  end
    
end ## end of def debug_me


def log_me(msg, opts={})
  debug_me({:tag => msg, :header => false}.merge(opts))
end


class StringOut
  attr_accessor :s
  def initialize
    @s=""
  end
  def puts a_string
    @s += a_string + '\n'
  end
  def flush
    @s
  end
end

######################################################
def xyzzy_me( &block )

  ev = nil 
  block_value = [ block.call ].flatten.compact  if block_given?
  block_value.map! { |v| v.to_s }
  ev = eval(block_value[0], block.binding)
  
  
  return ev
  
end ## end of def xyzzy_me( &block )
