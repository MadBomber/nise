#################################################################
###
##  File: Parameters.rb
##  Desc: The Parameters class processes a text file that has 'name=value' pairs.
##        The UIMDT SBPS program is an example of a program that produces this kind of file.
##
##  TODO: Consider refactoring those files that use this class to use the parseconfig gem
##        The parseconfig gem also parses files of name = value format.  It goes
##        further and process lines like [some_name] as section (or group) headers.
##        It also ignores blank lines and lines that start with the "#" sign.


require 'pathname'

class Parameters

  attr_reader   :pathname_
  attr_accessor :force_designation_
  attr_accessor :weapon_category_

  def initialize(filename=nil)

    raise "InvalidFileName: no filename was provided" if filename.nil?

    case filename.class.to_s
    when 'String' then
      @pathname_ = Pathname.new filename
    when 'Pathname' then
      @pathname_ = filename
    else
      raise "InvalidFileName: filename class not string or pathname."
    end

    raise "InvalidFileName: filename does not exist." unless @pathname_.exist?
         
    pf = File.open @pathname_.to_s, 'r'
    
    line_counter = 0

    while (a_line = pf.gets)

      a_line.strip!
      
#      next if '#' == a_line[0]   ## treat as a comment line

      unless a_line.empty?

        line_counter += 1
        puts "#{line_counter}: #{a_line}" if $debug

        # add_an_attribute a_line

        a     = a_line.split('=')

        pp a  if $debug
        
        name  = a[0].strip.downcase.to_sym

        if 2 == a.length
          value = a[1]
        else
          a[0] = nil
          a.compact!
          value = a.join('=')
        end

        puts "DEBUG: Adding #{name} with #{value}" if $debug

        add(name, value)

      end ## end of unless a_line.empty?

    end ## end of while (a_line = pf.gets)

    pf.close

  end ## end of def initialize(filename)
  
  
  ##################
  def include?(name)
    self.instance_variable_defined? "@#{name}"
  end ## end of def include?(name)
  
  
  ####################
  def add(name, value)
    self.instance_variable_set("@#{name}", value)
    self.class.send :attr_accessor, name
  end

end ## end of class Parameters
