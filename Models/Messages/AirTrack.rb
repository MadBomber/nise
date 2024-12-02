################################################################
###
##  File: AirTrack.rb (Link16 J3.2)
##  PURPOSE
##
##  The J3.2 Air Track message is used to exchange information on air tracks.
##
##

require 'Link16Message'
require 'LlaCoordinate'

################################
class AirTrack < Link16Message

  @@NULL_L16_LAT              = 1048576              # 2**21
  @@NULL_L16_LON              = 2097152              # 2**22

  @@MAX_L16_LAT               = 2097151              # 2**21-1
  @@MAX_L16_LON               = 4194303              # 2**22-1
  
  @@POS_DEG_TO_L16_FACTOR     = 11650.8444444444     # (2**20)/90.0
  @@POS_L16_TO_DEG_FACTOR     = 8.58306884765625e-05 # 90.0/(2**20)
  
  @@NEG_DEG_TO_L16_LAT_FACTOR = 11650.8222222222     # (2**20-2)/90.0
  @@NEG_DEG_TO_L16_LON_FACTOR = 11650.8333333333     # (2**21-2)/180.0
  @@NEG_L16_TO_DEG_LAT_FACTOR = 8.58308521859211e-05 # 90.0/(2**20-2)
  @@NEG_L16_TO_DEG_LON_FACTOR = 8.58307703311637e-05 # 180.0/(2**21-2)
  
  @@ALT_TO_L16_FACTOR         = 0.131233596          # convert meters to feet then scale in 25 foot increments
  @@L16_TO_ALT_FACTOR         = 7.6199999884176      # scale from 25 foot increments then convert feet to meters

  def initialize(data=nil)
    super
    desc "Link16 AirTrack Message"

    ## Link16Message inserts the first common items (4) accounting for the first 13 bits

    @label_j_series_      = 3   # J3.2
    @sublabel_j_series_   = 2


    ##################################################
    # J3.2/i
    type(:exercise_indicator_,                           '1')
    type(:ppli_track_number_and_identity_indicator_,     '0')
    type(:force_tell_indicator_,                         '0')
    type(:emergency_indicator_,                          '0')
    type(:special_processing_indicator_,                 '0')
    type(:simulation_indicator_,                         '1')
    type(:track_number_reference_, '10111_01000_000_000_000')   # 'RA000'
    type(:strength_,                                  '0111')
    type(:altitude_source_,                             '01')
    type(:altitude_25_ft_,                                13)       # need meter to feet conversion then divide by 25
    type(:identity_difference_indicator_,                '0')
    type(:track_quality_,                             '0111')
    type(:identity_confidence_,                       '0111')
    type(:identity_amplifying_descriptor_,             '111')   ## 0=yellow(pending); 3=blue; 6=red
    type(:special_interest_indicator_,                   '0')
    type(:unused_padding_,                                10)   ## Added for SimpleProtocol; not present over-the-air

    # J3.2/e0
    type(:word_format_e0_,                  '10')
    type(:spare_1_,                            2)
    type(:latitude_,                          21) # Integer( lat / 0.0051)
    type(:disused_1_,                          1)
    type(:spare_2_,                            1)
    type(:longitude_,                         22) # Integer( lon / 0.0051)
    type(:passive_active_indicator_,         '1')
    type(:course_,                 '1_1111_1111') # <= decimal 511 means no statement (in 1 degree increments)
    type(:speed_,                '111_1111_1111') # <= decimal 2047 is no statement; in data miles per hour
    type(:spare_3_,                           10)

    # J3.2/c1
    type(:word_format_c1_,                  '01')
    type(:continuation_word_label_,      '00001')
    type(:air_specific_type_indicator_,      '0')
    type(:mode_i_code_,                        5)
    type(:mode_ii_code_,                      12)
    type(:mode_iii_code_,                     12)
    type(:mode_iv_indicator_,                  2)
    type(:ppli_iff_sif_indicator_,          '00')
    type(:air_platform_,                       6) # default 0 means no statement
    type(:air_activity_,                       7) # default 0 means no statement
    type(:spare_4_,                            5)
    type(:minute_,                     '11_1111') # <= decimal 63 is no statement
    type(:hour_,                        '1_1111') # <= decimal 31 is no statement
    type(:spare_5_,                           10)

    # after these are all declared, compute max_size (which is bytes)
    @max_size = (@max_size_bits/8.0).ceil

    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end

  end ## end of def initialize


  ################################################
  ## Convert an LlaCoordinate or an Array into the
  ## proper values to be transmitted
  ## lla is in decimal degrees latitude and longitude
  ## altitude is in decimal meters
  def set_lla(lla_parm)

    case lla_parm.class.to_s
      when 'Array' then
        # assume that its [latitude, longitude, altitude]
        lla = lla_parm
        lla << 0.0 if 2 == lla.length   # use 0.0 meters if no altitude given
      when 'LlaCoordinate' then
        lla = [lla_parm.lat, lla_parm.lng, lla_parm.alt]
      else
        $stderr.puts "WARNING: AirTrack#set_lla called with invalid parameter class: #{lla_parm.class} value: #{lla_parm.inspect}"
    end
    
    if lla[0] < 0.0
      @latitude_ = Integer(@@MAX_L16_LAT + lla[0] * @@NEG_DEG_TO_L16_LAT_FACTOR)
    else
      @latitude_ = Integer(lla[0] * @@POS_DEG_TO_L16_FACTOR)
    end
    
    if lla[1] < 0.0
      @longitude_ = Integer(@@MAX_L16_LON + lla[1] * @@NEG_DEG_TO_L16_LON_FACTOR)
    else
      @longitude_ = Integer(lla[1] * @@POS_DEG_TO_L16_FACTOR)
    end
    
    @altitude_25_ft_ = Integer(lla[2] * @@ALT_TO_L16_FACTOR)
  end

  ################################################
  ## Convert the received latitude, longitude and
  ## altitude values into an LlaCoordinate
  def get_lla

    lla = LlaCoordinate.new
  
    if @latitude_ > @@NULL_L16_LAT
      lla.lat = (@latitude_ - @@MAX_L16_LAT).to_f * @@NEG_L16_TO_DEG_LAT_FACTOR
    else
      lla.lat = @latitude_.to_f * @@POS_L16_TO_DEG_FACTOR
    end
    
    if @longitude_ > @@NULL_L16_LON
      lla.lng = (@longitude_ - @@MAX_L16_LON).to_f * @@NEG_L16_TO_DEG_LON_FACTOR
    else
      lla.lng = @longitude_.to_f * @@POS_L16_TO_DEG_FACTOR
    end
    
    lla.alt   = @altitude_25_ft_.to_f * @@L16_TO_ALT_FACTOR

    return lla

  end


end ## end of class AirTrack

=begin
               j3.2e0
data element__________________# bits
word format                        2 '10'
spare                              2
latitude, 0.0051 minute           21 Integer( lat / 0.0051)
disused                            1
spare                              1
longitude, 0.0051 minute          22 Integer( lon / 0.0051)
passive/active indicator           1 '1'
course                             9 <= decimal 511 means no statement (in 1 degree increments)
speed                             11 <= decimal 2047 is no statement; in data miles per hour

               j3.2c1
data element__________________# bits
word format                        2 '01'
continuation word label            5 '00001'
air specific type indicator        1 '0'
mode i code                        5
mode ii code                      12
mode iii code                     12
mode iv indicator                  2
ppli iff/sif indicator             2 '00'
air platform(6)****************
air activity(7)               *
air specific type(12)         *   13
spare(1)***********************
spare                              5
minute                             6 <= decimal 31 is no statement
hour                               5 <= decimal 63 is no statement

       j3.2c2 (needline only)
data element__________________# bits
word format                        2 '01'
continuation word label            5 '00010'
variance xx                        8 <= decimal 255 is no statement
variance yy                        8
variance zz                        8
variance xy                        9 <= decimal 511 is no statement
variance xz                        9
variance yz                        9
spare                             12

       j3.2c3 (needline only)
data element__________________# bits
word format                        2 '01'
continuation word label            5 '00011'
dive angle                         8 <= decimal 255 no statement
second                             6 <= decimal 63 no statement
hundredths                         7 <= decimal 127 no statement
spare                             42

               j3.2c4
data element__________________# bits
word format                        2 '01'
continuation word label            5 '00100'
callsign, published               54 nine groups of 6-bits
spare                              9


Character coding for callsign field

Character             Decimal Value
---------             -------------
BLANK                     0
1                         1
2                         2
3                         3
4                         4
5                         5
6                         6
7                         7
8                         8
9                         9
A                         10
B                         11
C                         12
D                         13
E                         14
F                         15
G                         16
H                         17
I                         18
J                         19
K                         20
L                         21
M                         22
N                         23
O                         24
P                         25
Q                         26
R                         27
S                         28
T                         29
U                         30
V                         31
W                         32
X                         33
Y                         34
Z                         35
UNDEFINED                 36 THROUGH 62
ZERO                      63



=end


