#!/usr/bin/env ruby
##################################################################
###
##  File: decoder.rb
##  Desc: Takes a hex string and turns it into a fully decomposed ISE message
#

$OPTIONS = Hash.new
$OPTIONS[:unit_number] = 1

require 'rubygems'
require 'string_mods'
require 'IseDatabase'
require 'SamsonHeader'
#require 'ControlMessages'
require 'SimMsgType'
SimMsgType.new



unknown_hex_str = ARGV[0]
uhs_length      = unknown_hex_str.length
unknown_str     = ""

x = 0
while x < uhs_length do
  a_str = "0x" + unknown_hex_str[x,2]
  a_int = Integer(a_str)
  a_chr = a_int.chr
  unknown_str += a_chr
  x += 2
end


begin
  sh = SamsonHeader.new unknown_str
rescue
  puts "Not a SamsonHeader; length is #{unknown_str.length}"
  exit -1
end

puts
puts "Header type_ is: #{SimMsgType.get_desc_(sh.type_)}"

if sh.app_msg_id_ > 0
  am = AppMessage.find(sh.app_msg_id_)
  puts " app_msg_id_ is: (#{sh.app_msg_id_}) #{am.app_message_key} -- #{am.description}"
end

puts
puts sh.to_s

if sh.message_length_ > 0
  rc     = eval("require '" + am.app_message_key + "'")
  im     = eval(am.app_message_key + ".new")
  im.raw = unknown_str[$samson_header_length,sh.message_length_]
  im.unpack_message(sh.flags_)
  puts
  puts im.to_s
  puts
  puts im.explode_items
end

puts




