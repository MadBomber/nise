#!/usr/bin/env ruby
###########################################################
###
##  File:   kml_to_csv.rb
##  Desc:   convert a KML file into a csv file
##          The KML file is formated for viewing within Google Earth
##          This means that its position data is in the form
##          longitude,latitude,altitude
##
##          output is to standard out
##
##  This implementation is specific to converting segmented line representations
##  in KML into way-points for use by the way-point ISE model.
#

# FIXME: take the default speed from the command line

DEFAULT_SPEED_KILOMETERS_PER_HOUR = 600.0
DEFAULT_SPEED_METERS_PER_SECOND   = DEFAULT_SPEED_KILOMETERS_PER_HOUR / 60.0 / 60.0 / 1000.0   # 0.1666

require 'LlaCoordinate'
require 'EcefCoordinate'
require 'rexml/document'
require 'pathname'
require 'pp'

include REXML

usage_notice = String.new <<EOF

Usage: [-d] [--lla|--ecef] path_to_kml_file

Where:

  -d          turn on load debugging output ($debug)

  --lla       (default) output position as latitude, longitude, altitude
  --ecef      output position as Earth Centric Earth Fixed (ECEF)

  
  path_to_kml_file  is the path to the KML file to be converted

  The CSV file will be written to standard output (stdout)

EOF

if 1 > ARGV.length
  $stderr.puts usage_notice
  exit -1
end

if ARGV[0] == '-d'
  $debug = true
  ARGV.shift
else
  $debug = false
end


$ecef = false
$lla  = true

if ARGV[0] == '--lla'
  ARGV.shift
end

if ARGV[0] == '--ecef'
  $ecef = true
  $lla  = false
  ARGV.shift
end

if ARGV[0][0, 1] == '-'
  $stderr.puts usage_notice
  exit -1
end

kml_pathname = Pathname.new ARGV[0]

unless kml_pathname.exist?
  $stderr.puts
  $stderr.puts "ERRPR:  file does not exist"
  $stderr.puts usage_notice
  exit -1
end


if $lla
  output_header = "Latitude,Longitude,Altitude(m),Speed(m/s)"
end

if $ecef
  output_header = "ECEF-X,ECEF-Y,ECEF-Z,Speed(m/s)"
end

###################################
## Read the file into member
## Collect the xml elements

file = File.new(kml_pathname.to_s)
doc = Document.new(file)

root = doc.root

#############################
## Set up array of placemarks

placemarks = root.elements[1].get_elements "Placemark"

if placemarks.empty?
  placemarks = root.elements[1].elements["Folder"].get_elements "Placemark"
  if placemarks.empty?
    $stderr.puts
    $stderr.puts "ERROR: Could not find any 'Placemark' elements in the file."
    $stderr.puts
    exit -1
  end
end

number_of_placemarks = placemarks.length

if number_of_placemarks > 1
    $stderr.puts
    $stderr.puts "WARNING: The file contains multiple 'Placemark' elements."
    $stderr.puts "         A 'name' element seperater line will be included in the output."
    $stderr.puts
end

placemarks.each do |placemark|

  puts placemark if $debug
  
  placemark_name        = placemark.elements["name"].text
#  placemark_description = placemark.elements["description"].text

  puts "Name: #{placemark_name}" if number_of_placemarks > 1 or $debug
#  puts "Desc: #{placemark_description}"

  placemark_LineString_coordinates_element = placemark.elements["LineString"].elements["coordinates"]

  puts placemark_LineString_coordinates_element if $debug

  placemark_LineString_coordinates = placemark_LineString_coordinates_element.text

  placemark_LineString_coordinates if $debug

  waypoints = placemark_LineString_coordinates.split( %r{ \s*} )

  number_of_waypoints = waypoints.length - 1
  
  llpnts = []

  for x in 0 .. number_of_waypoints do
    waypoints[x].strip!
    waypoints[x] = waypoints[x].split(',')  # yea but, google's format is longitude, latitude, altitude
    
    if $debug
      llpnts << LlaCoordinate.new(waypoints[x][1].to_f, waypoints[x][0].to_f)
      
      if x > 0
        from_pnt = llpnts[x-1]
        to_pnt   = llpnts[x]
        $stderr.puts "#{from_pnt} -=> #{to_pnt}  d:#{from_pnt.distance_to(to_pnt)} h:#{from_pnt.heading_to(to_pnt)}"
      end
    
    end ## end if $debug
    
  end


  ##########################################
  ## write the CSV file
  
  puts output_header
  
  if $lla
    waypoints.each do |wp|
      puts "#{wp[1]},#{wp[0]},#{wp[2]},#{DEFAULT_SPEED_METERS_PER_SECOND}"   ## latitude, longitude, altitude, speed
    end
  end

  if $ecef
    waypoints.each do |wp|
      ecef = LlaCoordinate.new(wp[1].to_f, wp[0].to_f, wp[2].to_f).to_ecef
      puts "#{ecef.x},#{ecef.y},#{ecef.z},#{DEFAULT_SPEED_METERS_PER_SECOND}"   ## x, y, z , speed
    end
  end

end ## end of placemarks.each

$stderr.puts "Done."
