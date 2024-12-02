################################################################
###
##  File: TrackManagement.rb (Link16 J7.0)
##
##  PURPOSE
##
##  The J7.0 Track Management Message is used to transmit information necessary to effect management
##  actions on tracks being reported within the interface.  Management actions include dropping
##  tracks, reporting environment and identity conflicts, changing environment and identity,
##  changing alert status, and changing strength.
#

require 'Link16Message'

################################
class TrackManagement < Link16Message

  def initialize(data=nil)
    super()     ## Link16Message inserts the first common items (4) accounting for the first 13 bits
    desc "Link16 TrackManagement Message"

    ######################################
    # J7.0/i
    type(:exercise_indicator_,          '1')    # indicate a simulation
    type(:action_track_management_,   '000')    # 0=Drop Track
    type(:spare1_,                      '0')
    type(:controlling_unit_indicator_,  '1')    # The track controller said so
    type(:track_number_reference_,     '00000_00000_000_000_000') # Two alpha followed by 3 octal numbs
    type(:strength_,                 '0001')    # 0=No statement, 1=One unit
    type(:alert_status_change_,         '0')    # 0=Clear Alert Status, 1=Set Alert Status
    type(:platform_,              '00_0000')    # 0=No Statement, 

        #space_platform
        #air_platform
        #surface_platform
        #subsurface_platform
        #land_platform

    type(:activity_,             '000_0000')

        #space_activity
        #air_activity
        #surface_activity
        #subsurface_activity
        #land_activity

    type(:spare2_,                         '000')
    type(:environment_,                    '000')
    type(:identity_confidence_,           '0000')
    type(:identity_amplifying_descriptor_, '000')
    type(:special_interest_indicator_,       '0')
    type(:unused_padding_,        '00_0000_0000')   ## Added for SimpleProtocol; not present over-the-air

    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end

  end ## end of def initialize

end ## end of class TrackManagement




=begin
               j7.0e0
data element__________________# bits
word format                        2
strength, total number of          4
  vehicles
strength, percent of tracked       4
  vehicles
spare                             60

               j7.0c1
data element__________________# bits
word format                        2
continuation word label            5
space specific type(12)********
air specific type(12)         *
surface specific type(12)     *
subsurface specific type(12)  *
land specific type(12)        *   12
spare(12)**********************
spare                             51

=end
