########################################################
###
##  File: $HOME/.irbrc
##  Desc: Loaded by irb at initialization
#

puts "Loading custom environment from $HOME/.irbrc ..."

require 'rubygems'  if ENV['RUBY_VERSION'].include? '1.8'
require 'pathname'
require 'pp'

HERE = Pathname.pwd
HOME = Pathname.new ENV['HOME']

def tramp_require(what, &block)
  loaded, require_result = false, nil

  begin
    require_result = require what
    loaded = true

  rescue Exception => ex
    puts "** Unable to require '#{what}'"
    puts "--> #{ex.class}: #{ex.message}"
  end

  yield if loaded and block_given?

  require_result
end



tramp_require 'awesome_print'


##################################################


tramp_require 'sketches' do                 # See: http://sketches.rubyforge.org/

  Sketches.config :editor => 'gedit'
  # Commands to remember:
  # sketch                              Start a new code sketch
  # sketch 2                            Reopen a code sketch
  # sketch :foo                         Reopen a named code sketch
  # sketch_from 'path/to/bar.rb'        Open a code sketch from an existing file
  # sketches                            List code sketches
  # name_sketch 2, :foo                 Name a code sketch
  # save_sketch :foo, 'path/to/foo.rb'  Same a code sketch to a file

end

tramp_require 'hirb'

tramp_require 'looksee'

=begin
tramp_require('wirble') do
  Wirble.init(:skip_prompt=>true)
  
#  colors = Wirble::Colorize.colors.merge({
#    :object_class => :black,
#    :class        => :dark_gray,
#    :symbol       => :red,
#    :symbol_prefix=> :blue,
#  })

  # start wirble (with color)
  # set the colors used by Wirble
#  Wirble::Colorize.colors = colors

  Wirble.colorize
end
=end

=begin
tramp_require 'guessmethod' do
  GuessMethodOptions[:insert_weight]        = 1 ## default is 1
  GuessMethodOptions[:delete_weight]        = 1 ## default is 1
  GuessMethodOptions[:substitution_weight]  = 1 ## default is 1
  GuessMethodOptions[:threshold]            = 2 ## default is 2
  GuessMethodOptions[:active]           = true  ## default is true; set to nil if GuessMethod gets in the way
end
=end


# tramp_require 'IseDispatcher'       ## all the dispatcher classes and utility methods
# tramp_require 'IseDatabase'         ## all the database classes and utility methods


#######################################################
# Quick benchmarking
# Based on rue's irbrc => http://pastie.org/179534
#
# Can be used like this for the default 100 executions:
#
#       quick { rand }
#
# Or like this for more:
#
#     quick(10000) { rand }
#
#def quick(repetitions=100, &block)
#  require 'benchmark'
#
#  Benchmark.bmbm do |b|
#    b.report {repetitions.times &block} 
#  end
#  nil
#end

#########################################################
## Constants for testing new methods on hashes and arrays

HASH = { 
  :bob   => 'Marley', :mom   => 'Barley', 
  :bikes => 'Harley', :chris => 'Farley'} unless defined?(HASH)
ARRAY = HASH.keys unless defined?(ARRAY)

###########################################################
## Some helpful base class over-rides

# Easily print methods local to an object's class

class Object
  def local_methods
    instance_methods(false)
  end
end


##################################
## some IRB config options

IRB.conf[:AUTO_INDENT] = true


#################################
## Load up the local .irbrc files

# found_home = false

HERE.descend do |here|
#  unless found_home
#    found_home = here == HOME
#    next
#  end
  rc = here + '.irbrc'
  if rc.exist? and not ( here == HOME )
    puts "Loading #{rc} ..."
    load rc
  end
end

###############################
## Common alias of irb commands

alias q exit
alias rq require

puts 'Ready.'

