#####################################################################
###
##  File:  datetime_mods.rb
##  Desc:  Modifications to the Array class.
#

class Time

  def before(thing)
    return (self <= thing)
  end ## end of def before(thing)

  def after(thing)
    return (self >= thing)
  end ## end of def after(thing)

end ## end of class Time

############################################################
class DateTime

  def before(thing)
    return (self <= thing)
  end ## end of def before(thing)

  def after(thing)
    return (self >= thing)
  end ## end of def after(thing)

end ## end of class DateTime


