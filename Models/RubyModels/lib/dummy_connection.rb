#####################################################
###
##  File:  dummy_connection.rb
##  Desc:  Used for testing outside of the IseRubyPeer
#

class DummyConnection

  ############################
  def publish_message(message)
    puts "==== publish_message in #{self.class} was called with #{message.class} ===="
  end
  
  ##############################
  def subscribe_message(*args)
    puts "==== subscribe_message in #{self.class} was called with #{args.length} arguments ===="
    args.each do |a|
      puts "      #{a.class}"
    end    
  end
  
  ############################
  def subscribe_special(*args)
    puts "==== subscribe_special in #{self.class} was called with #{args.length} arguments ===="
    args.each do |a|
      puts "      #{a.class}"
    end
  end
  
  ####################
  def subscribed(*args)
    puts "==== subscribe_special in #{self.class} was called with #{args.length} arguments ===="
    args.each do |a|
      puts "      #{a.class}"
    end
    return {'dummy_key' => 'dummy_value'}
  end

end ## end of class DummyConnection

$connection = DummyConnection.new

