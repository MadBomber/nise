#####################################################################
###
##  File:  kernel_mods.rb
##  Desc:  Modifications to the Kernel module.
#

####################################################
## how to get access to the name of the currently
## executing method.

module Kernel
 private
    def this_method_name
      caller[0] =~ /`([^']*)'/ and $1
    end
end

=begin
class Foo
 def test_method
   this_method_name
 end
end

puts Foo.new.test_method    # => test_method
=end

################################################
## This is a way to establish class level
## interface specifications.  A virtual method is
## one in which the super-class expects the sub-class
## to implement.  If the method is called without
## being defined by the subclass, then the exception
## is thrown.

class VirtualMethodCalledError < RuntimeError
  attr :name
  def initialize(name)
    super("Virtual function '#{name}' called")
    @name = name
  end
end

class Module
  def virtual(*methods)
    methods.each do |m|
      define_method(m) {
        raise VirtualMethodCalledError, m
      }
    end
  end
end


# The usage is beautifully simple:
=begin
class VirtualThingy
  virtual :doThingy
end

class ConcreteThingy < VirtualThingy
  def doThingy
    puts "Doin' my thing!"
  end
end

begin
  VirtualThingy.new.doThingy
rescue VirtualMethodCalledError => e
  raise unless e.name == :doThingy
end
ConcreteThingy.new.doThingy

=end

