#################################################################
###
##  File: StkEphemeris.rb
##  Desc: The StkEphemeris class processes an STK Ephemeris file (*.e) into an array
#

require 'EphemerisArray'
require 'pathname'
require 'ostruct'
require 'string_mods'
require 'chronic'

class StkEphemeris

  attr_accessor :pathname             # The path to the data file
  attr_accessor :stk_version          # The STK format version for this file
  attr_accessor :flight_plan     # A positional array in 4D; time, latitude, longitude, altitude

  alias :ep :flight_plan

  #########################
  def initialize(filename=nil)

    throw :InvalidFileName if filename.nil?

    case filename.class.to_s
    when 'String' then
      @pathname = Pathname.new filename
    when 'Pathname' then
      @pathname = filename
    else
      throw :InvalidFileName
    end

    throw :InvalidFileName unless @pathname.exist?

    ef = File.open @pathname.to_s, 'r'

    line_counter = 0
    data_counter = 0

    @flight_plan = EphemerisArray.new

    while (a_line = ef.gets)

      a_line.strip!

      unless a_line.empty?

        line_counter += 1
        puts "#{line_counter}: #{a_line}"

        if 1 == line_counter
          @stk_version = a_line
          puts "DEBUG: Found stk_version -=>[#{@stk_version}]<=-"
        else

          case a_line.downcase
          when 'begin ephemeris' then       # begins attribute block
          when 'end ephemeris' then         # ends data points
          when 'ephemerisllatimepos' then   # ends attribute block; starts data points
            while ( data_counter < @number_of_ephemeris_points) # FIXME: assumes perfect file content

              a_line = ef.gets
              a_line.strip!

              unless a_line.empty?
                data_counter += 1
                an_array = a_line.split
                an_array.each_index do |x|
                  an_array[x] = an_array[x].to_f
                end
                flight_plan.add an_array
              end
            end

          else
            # add_an_attribute a_line


            a     = a_line.split
            pp a
            name  = a[0].to_underscore.to_sym


            if 2 == a.length
              value = a[1]
              value = value.to_i if :number_of_ephemeris_points == name
            else
              a[0] = nil
              a.compact!
              value = a.join(' ')
              if :scenario_epoch == name
                x = a.length
                a[x-1] = "12:00:00"
                value = Chronic.parse(a.join(' '))
              end
            end

            puts "DEBUG: Defining #{name} as #{value}"

            self.instance_variable_set("@#{name}", value)
            self.class.send :attr_accessor, name

          end ## end of case a_line.downcase

        end ## end of if 1 == counter

      end ## end of unless a_line.empty?

    end ## end of while (a_line = ef.gets)
    
    ef.close

  end ## end of def initialize

end ## end of class StkEphemeris

# The following comment block shows a *.e file format.
# Note that blank lines are ignored.

=begin
stk.v.5.0

BEGIN Ephemeris

NumberOfEphemerisPoints 552
ScenarioEpoch           30 September 2009 12:20:00.000000000
InterpolationMethod     Lagrange
InterpolationOrder      1
DistanceUnit		Kilometers
CentralBody             Earth
CoordinateSystem        Fixed 

EphemerisLLATimePos

         1200.723               25.816               54.819            0.000021
 ... snip ... total of 552 entries
         1751.896               24.464               54.566            0.001801

END Ephemeris
=end



