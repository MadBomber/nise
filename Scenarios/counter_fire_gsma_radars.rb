#############################################################################
###
##  Name:   counter_fire_gsma_radars.rb
##
##  Desc:   An example scenario to illustrate the use of the StkRadarDriver.
##          The implacement locations are the Greater Seoul Metro Area (GSMA)
##
#

require 'Radar'


  
def init_radars

  radars = []

  ######################################################
  ## Define Search Radars
  
  radar_location  = [38.052438, 127.124346, 200.0] ## Lat, Long, Alt -- decimal degrees and meters
  range_data      = [3000.0, 500000.0]                ## [min, max] meters
  azimuth_data    = [10.0, 55.0, 10.0, 30.0]          ## [min, max, width, rate] degrees and deg/sec
  elevation_data  = [10.0, 65.0, 10.0, 10.0]          ## [min, max, width, rate] degrees and deg/sec
  target_type     = /icbm|cf/i                        ## Only look for ICBM threats ("i" means case insensitive)


  radars << Radar.new("searcher_01", radar_location, range_data, azimuth_data, elevation_data, target_type)


  ##########################################
  ## Define Tracking Radars
  
  radar_location  = [37.81265882971723, 126.8774007941036, 200.0] ## Lat, Long, Alt -- decimal degrees and meters
  range_data      = [3000.0, 600000.0]    ## [min, max] meters

  radar_tracking_beam_width  = 4.0  ## SMELL: StkRadarDriver hardcodes 4 * this for searching beam width

  azimuth_data    = [45.0, radar_tracking_beam_width] ## [azimuth, width] degrees
  elevation_data  = [45.0, radar_tracking_beam_width] ## [elevation, width] degrees
  target_type     = /icbm|cf/i                        ## Only track ICBM threats or cf -- counter fire rockets
  
  radars << StaringRadar.new("tracker_01", radar_location, range_data, azimuth_data, elevation_data, target_type)



  
  
  ###########################################################
  ## Another Search Radar at the naval base.
  
  radar_location          = [35.15108479501102, 128.6404605170973, 200.0]
  range_data              = [3000.0, 400000.0]        ## [min, max] meters
  revolutions_per_minute  = 10.0                      ## RPM
  azimuth_width           = 10.0                      ## width of beam
  elevation_data          = [10.0, 65.0, 10.0, 10.0]  ## [min, max, width, rate]
  target_type             = /icbm_02/i                ## only look for icbm_02
    
  radars << RotatingRadar.new(  "searcher_02",
                                radar_location, 
                                range_data, 
                                revolutions_per_minute, 
                                azimuth_width, 
                                elevation_data, 
                                target_type
                             ) ## take the defaults on range, elevation and RPM
  
  return radars
  
end ## end of init_radars




## The End
##################################################################

