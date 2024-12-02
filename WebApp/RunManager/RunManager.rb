#!/usr/bin/env ruby
################################################################################
###
##	File:  RunManager.rb
##	Desc:  Provides IseRun managerment, see the wiki topic IseRunManager
#

APP_ROOT = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'sinatra'
require 'haml'

set :root, APP_ROOT

###################################################################
## Place-holder
get '/' do
  haml :index
end

###################################################################
## Place-holder

