###############################################
###
##   File:   <%= message_name.to_camelcase %>.rb
##   Desc:   <%= message_desc %>
##
#

require 'IseMessage'

class <%= message_name.to_camelcase %> < IseMessage
  def initialize
    super
    desc "<%= message_desc %>"
    # An IseMessage is not required to have any data items/components/elements.
    # A dataless message is perfectly legal.  It can be used as an event signal.
    #
    # A message that has data items must define the message items in the order
    # that they appear within a binary block.
    #
    # All IseModels regardless of wither they process this message in binary on the wire
    # or as XML, JSON, or some other serialization format will use this same order
    # Note the use of the colon in front of the format name and the item name.  By
    # convention ISE has adopted the trailing underscore on item_names as a way to
    # visually designating a variable name which is a component of a message.
    #
    #      format_name       item_name
    # item(:double,          :time_)
    # item(:ascii_string12,  :threat_label_)
    # item(:ascii_string12,  :interceptor_label_)
    # item(:ascii_string12,  :launcher_label_)
    #
    # Valid format names are shown in the README.txt file that is in this directory
  end
end
