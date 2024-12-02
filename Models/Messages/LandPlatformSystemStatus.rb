################################################################
###
##  File: LandPlatformSystemStatus.rb (Link16 J13.5)
##
##  PURPOSE
##
##  The J13.5 Land Platform and System Status Message provides the current operational weapons and
##  equipment status of a land platform.

require 'Link16Message'

################################
class LandPlatformSystemStatus < Link16Message

  def initialize(data=nil)
    super()     ## Link16Message inserts the first common items (4) accounting for the first 13 bits
    desc "Link16 LandPlatformSystemStatus Message"

    type(:operational_capability_,      2)
    type(:track_number_reference_,     19)
    type(:site_type_,                   6)
    type(:hot_inventory_,               7)
    type(:sam_mode_state_,              3)
    type(:time_function1_,              3)
    type(:minute1_,                     6)
    type(:hour1_,                       5)
    type(:perimeter_engagement_status_, 1)
    type(:spare_,                       5)
    type(:unused_padding_,             10)   ## Added for SimpleProtocol; not present over-the-air
    
    ############################
    # J13.5/c1
    
    type(:word_format2_,                      '01')   ## '01' a continuation word
    type(:continuation_word_label2_,       '00001')
    type(:cold_inventory_,                       7)
    type(:operational_impairment_,               5)
    type(:nato_link_1_status_,                   2)
    type(:link_14_status_,                       2)
    type(:link_11_status_,                       3)
    type(:link_11b_status_,                      2)
    type(:link_16_status_,                       3)
    type(:atdl_1_status_,                        2)
    type(:ijms_status_,                          2)
    type(:communications_impairment_,            3)
    type(:control_positions_,                    5)
    type(:time_function2_,                       3)
    type(:minute2_,                              6)
    type(:hour2_,                                5)
    type(:primary_surveillance_radar_status_,    2)
    type(:secondary_surveillance_radar_status_,  2)
    type(:tertiary_surveillance_radar_status_,   2)
    type(:acquisition_radar_status_,             2)
    type(:illuminating_radar_status_,            1)
    type(:mode_iv_interrogator_status_,          1)
    type(:iff_sif_interrogator_status_,          2)
    type(:spare2_,                               1)
    type(:unused_padding2_,                     10)   ## Added for SimpleProtocol; not present over-the-air


    ############################
    # J13.5/c2
    
    type(:word_format3_,                      '01')   ## '01' a continuation word
    type(:continuation_word_label3_,       '00010')
    type(:junk3_,                               73)


    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end

  end ## end of def initialize

end ## end of class LandPlatformSystemStatus






=begin

              j13.5c1
data element__________________# bits
word format                        2
continuation word label            5
cold inventory                     7
operational impairment             5
nato link 1 status                 2
link 14 status                     2
link 11 status                     3
link 11b status                    2
link 16 status                     3
atdl 1 status                      2
ijms status                        2
communications impairment          3
control positions                  5
time function                      3
minute                             6
hour                               5
primary surveillance radar         2
  status
secondary surveillance radar       2
  status
tertiary surveillance radar        2
  status
acquisition radar status           2
illuminating radar status          1
mode iv interrogator status        1
iff_sif interrogator status        2
spare                              1


=end
