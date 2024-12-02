###########################################################
###
##  File: object_class_mods.rb
##  Desc: modifications to basic class
#
require 'pp'

class Object

  def web_inspect
    s = '<pre>'
    s += self.pretty_inspect.gsub('<','&lt;').gsub('>', '&gt;').gsub(' ','&nbsp;')
    s += '</pre>'
    return s
  end
  
end
    
