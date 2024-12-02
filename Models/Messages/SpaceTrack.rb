################################################################
###
##  File: SpaceTrack.rb     (Link16 J3.6)
##  PURPOSE
##
##  The J3.6 Space Track message is used to exchange information on Space and Ballistic Missile
##  tracks.
#

require 'Link16Message'

################################
class SpaceTrack < Link16Message

  def initialize(data=nil)
    super
    desc "Link16 SpaceTrack Message"

    ## Link16Message inserts the first common items (4) accounting for the first 13 bits

    @label_j_series_      = 3   # J3.6
    @sublabel_j_series_   = 6


    ###############################
    # J3.6/i
    type(:disused_,            '0')
    type(:force_tell_,         '0')
    type(:special_proc_,       '0')
    type(:sim_indic_,          '0')
    type(:space_indic_,        '0')

#    type(:tn_ls_3_bit_,        '000')     # unitID least significant character
#    type(:tn_mid_3_bit_,       '000')     # unitID next significant character
#    type(:tn_ms_3_bit_,        '001')     # unitID most significant character
#    type(:tn_ls_5_bit_,        '10011')   # 0x13; // "M" -=> Missile
#    type(:tn_ms_5_bit_,        '10111')   # 0x17; // "R" -=> Red

    type(:track_number_reference_, '10111_10011_000_000_000')   # 'RM000'

    type(:minute_,             '111111')
    type(:second_,             '111111')
    type(:track_quality_,      '0111')
    type(:identity_,           '0011')
    type(:space_platform_,     '000000')
    type(:space_activ_,        '0000000')
    type(:unused0_,            '0000000000')

    ###############################
    # J3.6/e0

    # NOTE: x,y,z AND vx, vy, vz are in FEET

    type(:word_format1_,       '10')
    type(:x_position_,         '00100011110001101100111') # scale(x,  0.1,      0x800000);
    type(:x_velocity_,         '11111011010011')          # scale(vx, 1.0/3.33, 0x2000);
    type(:y_position_,         '00000101111001100110111') # scale(y,  0.1,      0x800000);
    type(:space_amplification_,'00000')
    type(:amplification_conf_, '000')
    type(:unused1_,            '0000000000')

    ###############################
    # J3.6/e1
    type(:word_format2_,       '10')
    type(:y_velocity_,         '00001100001010')          # scale(vy, 1.0/3.33, 0x2000);
    type(:z_position_,         '00110100011001100011101') # scale(z,  0.1,      0x800000);
    type(:z_velocity_,         '00001001011110')          # scale(vz, 1.0/3.33, 0x2000);
    type(:lost_track_,         '0')
    type(:boost_indicator_,    '0')
    type(:data_indicator_,     '000')
    type(:spare_,              '000000000000')
    type(:unused2_,            '0000000000')

    # after these are all declared, compute max_size (which is bytes)
    @max_size = (@max_size_bits/8.0).ceil

    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end

  end ## end of def initialize

  #######################################
  ## use this scaling routine with the
  ## X,Y,Z position and velocity
  def self.scale(val, factor, neg_offset)

    ival = Integer(val * factor)
    ival += neg_offset if (val < 0.0)
    return ival

  end

end ## end of class SpaceTrack



=begin
               j3.6i
data element__________________# bits


disused                            1
force tell indicator               1
special processing indicator       1
simulation indicator               1
space specific type indicator      1
track number, reference           19
minute                             6
second                             6
track quality, 1                   4
identity(3)********************    3
disused(3)*********************
identity difference indicator      1
space specific type(12)********
spare(1)                      *
space platform(6)             *   13
space activity(7)**************

               j3.6e0
data element__________________# bits
word format                        2
x position in wgs-84              23
x velocity in wgs-84              14
y position in wgs-84              23
space amplification                5
amplification confidence           3

               j3.6e1
data element__________________# bits
word format                        2
y velocity in wgs-84              14
z position in wgs-84              23
z velocity in wgs-84              14
lost track indicator               1
boost indicator                    1
data indicator                     3
spare                             12

               j3.6c1
data element__________________# bits
word format                        2
continuation word label            5
sigma x position                  10
sigma y position                  10
sigma z position                  10
covariance data element 22        10
covariance data element 33        10
sign of covariance data            1
  element 23
absolute value of covariance      10
  data element 23
sign of covariance data            1
  element 12
sign of covariance data            1
  element 13

               j3.6c2
data element__________________# bits
word format                        2
continuation word label            5
sigma x velocity                  10
sigma y velocity                  10
sigma z velocity                  10
sign of covariance data            1
  element 24
absolute value of covariance      10
  data element 24
sign of covariance data            1
  element 34
absolute value of covariance      10
  data element 34
covariance data element 44        10
sign of covariance data            1
  element 14

               j3.6c3
data element__________________# bits
word format                        2
continuation word label            5
sign of covariance data            1
  element 25
absolute value of covariance      10
  data element 25
sign of covariance data            1
  element 35
absolute value of covariance      10
  data element 35
sign of covariance data            1
  element 45
absolute value of covariance      10
  data element 45
covariance data element 55        10
sign of covariance data            1
  element 15
ballistic missile beta(18)*****
ballistic missile             *   18
  acceleration(18)*************
spare                              1

               j3.6c4
data element__________________# bits
word format                        2
continuation word label            5
sign of covariance data            1
  element 26
absolute value of covariance      10
  data element 26
sign of covariance data            1
  element 36
absolute value of covariance      10
  data element 36
sign of covariance data            1
  element 46
absolute value of covariance      10
  data element 46
sign of covariance data            1
  element 56
absolute value of covariance      10
  data element 56
covariance data element 66        10
sign of covariance data            1
  element 16
spare                              8

               j3.6c5
data element__________________# bits
word format                        2
continuation word label            5
sigma x velocity                  10
sigma y velocity                  10
sigma z velocity                  10
velocity covariance data          10
  element 22

         j3.6c5 (continued)
data element__________________# bits
velocity covariance data          10
  element 33
sign of velocity covariance        1
  data element 23
absolute value of velocity        10
  covariance data element 23
sign of velocity covariance        1
  data element 12
sign of velocity covariance        1
  data element 13


=end
