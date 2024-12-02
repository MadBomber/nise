#####################################################################
###
##  File:  array_mods.rb
##  Desc:  Modifications to the Array class.
#

class Array

  def merge(thing)
  
    if 'Array' == thing.class.to_s
      a = self + thing
    else
      a = self << thing
    end
    
    a.uniq
  
  end ## end of def self.merge(thing)

end ## end of class Array


