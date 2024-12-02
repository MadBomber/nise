#!/usr/bin/env ruby
#####################################################
###
##  File: kml_placemarks_to_csv.rb
##  Desc: Convert placemark data in a folder into CSV format
#

require 'rexml/document'
include REXML
file=File.new("/home/dvanhoozer/UAE.kml") # FIXME: take the file path from the command line
doc=Document.new(file)
root=doc.root
folder = root[1].get_elements("Folder")
placemarks = folder[0].get_elements("Placemark")

puts "Name,Latitude,Longitude"

placemarks.each do |pm|
  name  = pm.elements["name"].text
  coord = pm.elements["Point"].elements["coordinates"].text
  lon_lat = coord.split(',')
  puts "#{name},#{lon_lat[1]},#{lon_lat[0]}"
end
