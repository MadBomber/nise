################################################################
###
##  File: LandPointPPLI.rb    (Link16 J2.5)
##
##  PURPOSE
##
##  The J2.5 Land Point PPLI message is used to provide all JUs information about stationary ground
##  JUs on the Link 16 network.  It is used by stationary ground JUs to provide network
##  participation status, identification, positional information and relative navigation
##  information.
##

require 'Link16Message'

################################
class LandPointPPLI < Link16Message

  # FIXME: delete this old stuff
  @@LAT_LON_CONVERTER = 90.0 / 4_194_303.0
  @@NEG_LAT_CONSTANT  = 4_194_304
  @@NEG_LON_CONSTANT  = 8_388_608   # two times the lat constance

  # FIXME: get the correct values (these came from AirTrack)
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




  def initialize(data=nil)
    super()     ## Link16Message inserts the first common items (4) accounting for the first 13 bits
    desc "Link16 LandPointPPLI Message"

    # J2.5/i
    type(:exercise_indicator_,                       '1')
    type(:displaced_position_indicator_,             '0')
    type(:force_tell_indicator_,                     '0')
    type(:emergency_indicator_,                      '0')
    type(:command_and_control_indicator_,            '0')
    type(:simulation_indicator_,                     '1')
    type(:spare1_,                                  '00')
    type(:active_wan_relay_indicator_,               '0')
    type(:rtt_reply_status_indicator_,               '0')
    type(:network_participation_status_indicator_,'0000')
    type(:time_quality_,                          '0100')
    type(:geodetic_position_quality_,             '1000')
    type(:strength_,                              '0001')
    type(:spare2_,                                   '0')
    type(:elevation_25_ft_,              '000_0000_0000')   # 25 foot increments
    type(:spare3_,                                  '00')
    type(:mission_correlator_,               '0000_0000')
    type(:elevation_quality_,                     '1000')
    type(:spare4_,                              '0_0000')
    type(:unused_padding_,                '00_0000_0000')   ## Added for SimpleProtocol; not present over-the-air

    ############################
    # J2.5/e0

    type(:word_format1_,                      '10') ## '10' marks a word extension
    type(:latitude_,                            23) ## SMELL units: 90 / 4194303 degrees (+4194304 for negative)
    type(:longitude_,                           24) ## SMELL units: 90 / 4194303 degrees
    type(:spare5_,                              21)
    type(:unused_padding2_,                     10)   ## Added for SimpleProtocol; not present over-the-air


    ############################
    # J2.5/c1

    type(:word_format2_,                        '01')   ## '01' a continuation word
    type(:continuation_word_label2_,         '00001')
    type(:voice_call_sign_indicator_,            '1')
    type(:spare6_,                                 1)
#    type(:voice_call_sign_, '001011_010101_000000_000000') ## 'BL  ' 24-bit field; 4 groups of 6 bits

    type(:voice_call_sign_char4of4_, '00_0000') ## ' '
    type(:voice_call_sign_char3of4_, '00_0000') ## ' '
    type(:voice_call_sign_char2of4_, '01_0101') ## 'L'
    type(:voice_call_sign_char1of4_, '00_1011') ## 'B'


    type(:land_platform_,                  '01_1000')   ## value 24: Missile Launcher
    type(:land_activity_,                 '010_1011')   ## value 43: defending
    type(:voice_frequency_channel_,               13)   ## value 0 is no statement
    type(:control_channel_,               '111_1111')   ## value 127 is no statement
    type(:active_relay_indicator_voice_channel_,   '0')
    type(:active_relay_indicator_control_channel_, '0')
    type(:voice_frequency_channel_indicator_,      '0')
    type(:spare7_,                                 1)
    type(:unused_padding3_,                       10)   ## Added for SimpleProtocol; not present over-the-air


    ############################
    # J2.5/c3

    type(:word_format3_,                      '01')   ## '01' a continuation word
    type(:continuation_word_label3_,       '00011')
    type(:spare8_,                               1)
    type(:u_coordinate_,'1000_0000_0000_0000_0000')   ## value 524288: no statement
    type(:v_coordinate_,'1000_0000_0000_0000_0000')
    type(:beta_angle_,        '100_0000_0000_0000')   ## value 16384: no statement
    type(:relative_position_quality_,       '1000')
    type(:relative_azimuth_quality_,         '100')
    type(:unused_padding4_,                     10)   ## Added for SimpleProtocol; not present over-the-air


    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end

  end ## end of def initialize


  #########################
  # FIXME: remove the old stuff add the new stuff
  def set_lat_lon(an_array)

    raise 'Must have an LLA array' unless 'Array' == an_array.class.to_s

    @latitude_    = Integer(an_array[0].abs / @@LAT_LON_CONVERTER)
    @longitude_   = Integer(an_array[1].abs / @@LAT_LON_CONVERTER)
    
    @latitude_    += @@NEG_LAT_CONSTANT if an_array[0] < 0.0
    @longitude_   += @@NEG_LON_CONSTANT if an_array[1] < 0.0

  end

  ###############
  # FIXME: remove the old stuff add the new stuff
  def get_lat_lon

    if @latitude_ > @@NEG_LAT_CONSTANT
      lat_neg = true
      @latitude_ -= @@NEG_LAT_CONSTANT
    else
      lat_neg = false
    end

    if @longitude_ > @@NEG_LON_CONSTANT
      lon_neg = true
      @longitude_ -= @@NEG_LON_CONSTANT
    else
      lon_neg = false
    end
    
    lat = @latitude_  * @@LAT_LON_CONVERTER
    lon = @longitude_ * @@LAT_LON_CONVERTER
    
    lat *= -1.0 if lat_neg
    lon *= -1.0 if lon_neg

    return [lat, lon]

  end ## end of def get_lat_lon


end ## end of class LandPointPPLI


=begin
               J2.5E0
DATA ELEMENT__________________# BITS
WORD FORMAT                        2
LATITUDE, 0.0013 MINUTE           23
LONGITUDE, 0.0013 MINUTE          24
SPARE                             21

               J2.5C1
DATA ELEMENT__________________# BITS
WORD FORMAT                        2
CONTINUATION WORD LABEL            5
VOICE CALL SIGN INDICATOR          1
SPARE                              1
VOICE CALL SIGN                   24
LAND PLATFORM                      6
LAND ACTIVITY                      7
VOICE FREQUENCY/CHANNEL           13
CONTROL CHANNEL                    7
ACTIVE RELAY INDICATOR VOICE CHANNEL     1
ACTIVE RELAY INDICATOR CONTROL CHANNEL            1
VOICE FREQUENCY CHANNELINDICATOR            1
SPARE                              1

               J2.5C3
DATA ELEMENT__________________# BITS
WORD FORMAT                        2
CONTINUATION WORD LABEL            5
SPARE                              1
U COORDINATE                      20
V COORDINATE                      20
BETA ANGLE                        15
RELATIVE POSITION QUALITY          4
RELATIVE AZIMUTH QUALITY           3

               J2.5C4
DATA ELEMENT__________________# BITS
WORD FORMAT                        2
CONTINUATION WORD LABEL            5
SPARE                              3
LATITUDE, 0.0103 MINUTE           20
SPARE                              3
LONGITUDE, 0.0103 MINUTE          21
SPARE                             16




Voice Call sign is 4 groups of 6 bits having the following coding:

Character               Value
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
0 (ZERO)                  63


=end
