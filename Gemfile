##################################################################
###
##  File:  Gemfile    from $ISE_ROOT
##  Desc:  A Ruby Gem configuration file used by the bundler gem.
##         bundler manages the gem configuration.  It can be used
##         to fetch the required gems from external internet sources.
##         The standard external source is rubygems.org
##
##  See:  http://rubygems.org/gems/bundler
##
##  To load the gem libraries required by ISE do the following sequence:
##    1) cd $ISE_ROOT           # must be in the ISE root directory to start
##    2) gem update --system    # updates the current system install gem support lib
##    3) gem install bundler    # installs the latest version of bundler
##    4) bundle install         # installs into a local directory all gems required by ISE
##
##  To package gems into the $ISE_ROOT/vendor/cache directory do this:
##    1) bundle package         # locks the bundle and copies all *.gem files into ./vendor/cache
##
##

source :rubygems                      # NOTE: rubygems.org is the standard gem repository

gem 'bundler'
gem 'therubyracer'
gem 'RedCloth'
gem 'configatron'
gem 'net-ssh'
gem 'snmp'

gem 'yell'                  # Your Extensible Logging Library
gem 'yell-adapters-gelf'
gem 'yell-adapters-syslog'
gem 'yell-rails'

#############################################
## System Library Replacements

unless 'java' == RUBY_PLATFORM.downcase
  gem 'home_run'                  # Replace for Date/DateTime (not 100% compat, see gem details)
end

#############################################
## Support Tools for automated testing and CI

gem "rake"                      # Ruby based make-like utility
#gem "rake-hooks"                # adds before/after method hooks on rake tasks
gem 'rtfm'                      # adds support for *nix man page creation


#############################################
## WebApps Using Rails

gem "rails"    # , "2.3.10"            # stuck at 2.3 because of schedule constraints

gem "formtastic" #,  "0.9.8"      # May need to revert to "0.9.7" because of problems with latest paperclip
gem "tabletastic" #, "0.1.3"      # table builder for Rails collections
gem "crummy" #,"0.1.0"            # breadcrumbs for rails
gem "xebec" #, "2.3.0"            # Navigation helpers for rails
gem "friendly_id" #, "2.3.2"      # comprehensive slugging and pretty-URL plugin for rails
#gem "twilson63-nifty-generators", "0.3.8" # collection of useful generator scripts for Rails
#gem "validation_reflection", "0.3.6"      # Adds reflective access to validations
#gem "has_many_polymorphs"       # ActiveRecord plugin for self-referential and double-sided polymorphic associations

#unless RUBY_VERSION.include?("1.8.6")
#  gem "enumerated_attribute"			# depends on meta_programming which is only 1.8.7 compatible
#end



#############################################
## Database (ActiveRecord) Helpers

gem "composite_primary_keys"  #, "2.3.5.1"     # only used by the run_messages table

unless 'java' == RUBY_PLATFORM.downcase
  gem "mysql2"                               # active_record adaptor to the MySQL database service
  gem 'activerecord-mysql2-adapter'

  group :development, :test do
    gem "sqlite3-ruby", :require => "sqlite3" # AR adaptor to the sqlite3 database service
  end
end


###############################################
## Key-Value Stores

unless 'java' == RUBY_PLATFORM.downcase
  gem 'localmemcache'             # persistent key-value(string) database based on mmap()'ed shared memory
end

gem "dalli"             # High performance memcached client for Ruby


###############################################
## Web Services

gem "sinatra"         # web application development framework for when rails is too heavy
gem "rest-client"     # Simple REST client


###############################################
## Web Servers

unless 'java' == RUBY_PLATFORM.downcase
  gem 'thin'             # A thin, eventmachine-based fast web server
end



###############################################
## Web Site Utilities (Javascript, HTML, CSS helpers)

#gem "RedCloth"        # Textile parser used by IsePortal (dispatcher list)
gem "json"            # JSON Implementation for Ruby
gem 'multi_json'

#gem "compass"         # Stylesheet Framework
#gem "bluecloth"       # implementation of Markdown syntax
#gem "haml"            # structured XHTML/XML templating engine
#gem "json_pure"       # JSON Implementation for Ruby
#gem "tilt"            # Generic interface to multiple Ruby template engines


###############################################
## File IO

unless 'java' == RUBY_PLATFORM.downcase
  gem "libxml-ruby"       # Ruby libxml bindings
end

gem "xml-simple"        # A simple API for XML processing
gem "rubyzip"           # work with zip files
gem "require_all"       # Loads files from a directory with dependency-knowledge



###############################################
## Network IO, HTTP, SNMP, AMQP, Sockets, TCP, UDP etc.

gem "eventmachine"      # THE reactor pattern for IO
gem "snmp"              # Simple Network Management Protocol
gem "net-ssh"           # secure shell
gem "dnssd"             # DNS Service Discovery - uses avahi libraries on *nix and bounjour on MacOSX
gem "bunny"             # Wrapper of the AMQP using event-machine
gem "amqp-utils"        # command line utilities for management of AMQP queues


group :development, :test do
  gem "net-scp"           # secure copy
  gem "net-sftp"          # secure ftp
  gem "net-ssh-gateway"   # assist in establishing tunneled Net::SSH connections
  gem "net-ssh-multi"     # Control multiple Net::SSH connections via a single interface
  gem "net-ssh-telnet"    # simple send/expect interface over SSH with an API almost identical to Net::Telnet
  gem "rye"               # Safely run SSH commands on a bunch of machines at the same time
  gem "couchdb"           # Access to a document-based database
  gem "couchdb-ruby"      # Access to a document-based database
  gem "mongoid"           # Access to a NoSQL database
end

gem 'notify'            # simple cross-platform user notification with little control over format
gem 'notifier'          # moroe complex cross-platform user notification with more control over format


###############################################
## Console IO

gem "highline"        # high-level command-line IO library
gem "term-ansicolor"  # colors strings using ANSI escape sequences
gem "templater"       # used by genise command
gem "colored"         # simular to term-ansicolor


###############################################
## Geodesic Support Libraries

gem "geokit"          # geocoding and distance calculation
gem "GeoRuby"         # Ruby data holder for OGC Simple Features
gem "geoutm"          # supports UTM coordinate conventions/conversions
#gem "vincenty"        # bearing and distance between two coordinates (may not be 1.9.2 compatiable)


###############################################
## System-level Utility Libraries

gem 'ffi'           # Provides a foreign function interface to native shared libraries
gem "systemu"       # like 'system' but returns exit_code, stdout and stderr to caller
gem 'syslogger'     # drop in replace for ruby's logger library

unless 'java' == RUBY_PLATFORM.downcase
  gem "sys-host"      # hostname and ip address info for a given host
end

group :development, :test do
  unless 'java' == RUBY_PLATFORM.downcase
    gem "sys-admin"       # A unified, cross platform replacement for the "etc" library
    gem "sys-cpu"         # interface for providing CPU information
    gem "sys-filesystem"  # interface for getting file system information
    gem "sys-uname"       # system platform information
  end
end


###############################################
## Misc. Utilities

gem "columnize"   # Read file with caching
gem "text-table"  # plain text table formatter
gem "uuid"        # UUID generator
gem "uuidtools"   # UUID generator
gem "facets"      # Premium Core Extensions and Standard Additions
gem "ruby-graphviz"	# supports 'bundle viz'
gem "blankslate"  # A BlankSlate object with most of the common Object stuff removed


###############################################
## Developer Utilities (Command-line and IRB)

gem "vclog"           # Cross-VCS/SCM ChangeLog Generator

group :development, :test do
  gem "awesome_print"   # like 'pp' but more awesome with color output
  gem "annotate"        # stopped working with rails 2.3+
  gem "dnote"           # scans code looking for developer note tags
  gem "pry"             # Starts an interactive session simular to IRB
  if RUBY_VERSION.include?("1.9")
    gem "ruby-debug19"  # Ruby version 1.9+ debugger
  else
    gem "ruby-debug"    # Ruby v1.8.7- debugger
  end
end


################################################
## irb utilities

group :development, :test do

  unless 'java' == RUBY_PLATFORM.downcase
    gem "looksee"           # irb extension that reports all valid methods on an object
  end

  gem "irbtools"            # set of irb extensions that includes the following
  gem "irbtools-more"       # more good stuff for irb

=begin

irbtools and irbtools/more metagems contain the following:

wirb                  # Colorizes resulting Ruby objects
paint                 # Provides easily to use terminal colors
hirb                  # Custom views for specific objects, e.g. tables for ActiveRecord
fancy_irb             # Hash rockets for results and colorful error messages
every_day_irb         # Contains helper methods that might be useful in every-day irb usage, see below for details
clipboard             # Easy clipboard access
interactive_editor    # Lets you open vim (or emacs) from within irb to hack something that gets loaded into the current session, also possible: yaml object editing
zucker                # Nice debug printing (q, o, c, Object#m, Object#d) and useful pseudo-constants (Info, OS, RubyVersion, RubyEngine)
ap                    # Alternative for displaying Ruby objects
coderay               # Colorizes Ruby code (colorize, ray)
boson                 # “A command/task framework similar to rake and thor that opens your ruby universe to the commandline and irb.”
methodfinder          # Interesting method finder (mf)
ori                   # Adds an Object#ri method
method_locator        # Provides Object#mlp (improved version of Module#ancestors) and Object#methods_for(m) (get this method from all ancestors)
method_source         # Object#src can be shown for Ruby methods

bond                  # irbtools-more: Improves irb tab-completion
looksee               # irbtools-more: Great load path inspector: Object#l (Extended version of Object#m), also provides the ability to Object#edit methods.
drx                   # irbtools-more: A tk object inspector, defines Object#see

fileutils (stdlib)    # Includes file system utility methods: cd, pwd, ln_s, mv, rm, mkdir, touch, … ;)

=end

end


################################################
## Unit test Support

group :development, :test do
  gem 'minitest'        # lightwieght Test::Unit replacement
  gem "ZenTest"         # provides cli tools: zentest, unit_diff, autotest, and multiruby
  gem "ae"              # extends Test::Unit with different syntactic sugar asserts
  gem "shoulda"         # sugar for unit tests

  gem "rspec", "1.3.0"           # unit testing framework
  gem "rspec-rails", "1.3.2"     # unit testing framework

  gem "ci_reporter"              # enables TestUnit to generate XML files for use with Hudson
  gem "hudson-remote-api"        # Access a Hudson CI Server for information
end


###############################################
## Quality Assurance Tools
## Static Code Analysis

group :development, :test do
  gem "rails_best_practices"    # reviews a rails project for potential problems

  gem 'flog'
  gem 'flay'
  gem 'reek'
  gem 'simplecov'

  gem "roodi"                   # Ruby Object Oriented Design Inferometer
end


###############################################
## Deployment and Configuration Tools

gem "configuration" # configuration system
gem "configatron"   # configuration system
gem "iniparse"      # library for parsing INI-like documents

gem "vlad"          # application deployment automation
gem 'chef'          # platform configuration management
gem 'chef-server'

group :development do
  gem 'guard'              # file watcher
  gem 'guard-annotate'
  gem 'guard-bundler'
  gem 'guard-coffeescript'
end


