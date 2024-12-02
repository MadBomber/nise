#####################################################################
###
##  File:  BlockMessage.rb
##  Desc:  Unstructured ISE Messages accomplished by over-riding most of the
##         IseMessage capability to support structured data.
#

require 'IseMessage'

class BlockMessage < IseMessage

  def initialize(a_string="")
    super
    desc "An Unstructured Block Message"
    raise "Init parm must be of class String not #{a_string.class}" unless 'String' == a_string.class.to_s
    @data = a_string
  end
  
  def item
    raise "Use an IseMessage in place of BlockMessage if you want structured messages"
  end
  
  def pack_message(unused_parm=nil)
    @data
  end
  
  def unpack_message(unused_parm=nil, another_unsed_parm=nil)
    @data
  end
  
  def data
    @data
  end
  
  def data=(a_string)
    raise "Invalid parameter class: #{a_string.class}" unless 'String' == a_string.class.to_s
    @data         = a_string
  end
  
  alias out data
  alias out= data=
  alias raw data
  alias raw= data=
  
  def hash
    {:data => @data}
  end
  
  alias to_h hash
  
  def msg_items
    [[:data, :string]]
  end
  
end ## end of class BlockMessage < IseMessage
