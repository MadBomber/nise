#!/usr/bin/env ruby

require 'rubygems'
require 'net/http'
require 'xml/libxml'

cnxn=Array.new

nodes = ENV["ISE_CLUSTER"].split(/\s* \s*/)
nodes.each do |node|
        str = ""
	Net::HTTP.start( node, 8010 ) do |http|
#	     print( http.get( '/connections.xml' ).body )
	     str << http.get( '/connections.xml' ).body
             #puts document.validate(schema)
	end
        #schema = XML::Schema.from_string(str)
        #schema = XML::Schema.from_string(str)
parser = XML::Parser::new
parser.string = str
#document = XML::Document.new
document = parser.parse
#puts document
#puts str
#puts "---"
root = document.root
#puts "Root element name: #{root.name}"
con = root.find('connection').to_a.first
#puts "con: #{con['class_id']}"
root.find('//boost_serialization/connection').each do |node|
#root.each do |node|
  cnxn << Hash.new
#puts "=> #{node.name}"
  #node.each_element {|el| puts "#{el.name} --> #{el.content}"
  node.each_element {|el|
    cnxn.last[el.name]=el.content
  }
puts "----"
  #puts "#{node.to_s} -> #{node.content}"
end
#        puts document.validate(document)
end

puts "#{cnxn.size}"
cnxn.each { 
  |c| c.each {|x,y| puts "#{x} -> #{y}"}
}
puts ""
puts cnxn[0]["connection_id"]
