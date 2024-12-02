#############################################################################
###
##  Name:   counter_fire_uae_one_searcher.rb
##
##  Desc:   An example scenario to illustrate the use of the StkRadarDriver.
##          The implacement locations are in the UAE
##
#

require 'Radar'


  
def init_radars

  radars = []

  ######################################################
  ## Define Search Radars
  
  #################
  ## SearchRadar_01
  ## Boresite: 0 deg
  ## Azimuth Min: 0 deg
  ## Azimuth Max: 360 deg
  ## Elevation Min: 2 deg
  ## Elevation Max: 45 deg
  ## Beam Width: 7 deg (Az)
  ## Update Rate: 5 deg/s
  
  radar_location  = [25.26052055530917, 55.3508101690813, 0.0] ## Lat, Long, Alt -- decimal degrees and meters

  range_data              = [3000.0, 400000.0]        ## [min, max] meters
  revolutions_per_minute  = 10.0                      ## RPM
  azimuth_width           = 10.0                      ## width of beam
  elevation_data          = [ 15.0, 30.0, 30.0, 5.0]  ## [min, max, width, rate]
  target_type             = /scud/i                ## only look for scud threats

  radars << RotatingRadar.new(  "SearchRadar_01",
                                radar_location, 
                                range_data, 
                                revolutions_per_minute, 
                                azimuth_width, 
                                elevation_data, 
                                target_type
                             )


  #################
  ## SearchRadar_02
  ## Boresite: 0 deg
  ## Azimuth Min: 0 deg
  ## Azimuth Max: 360 deg
  ## Elevation Min: 2 deg
  ## Elevation Max: 45 deg
  ## Beam Width: 7 deg (Az)
  ## Update Rate: 5 deg/s
=begin
  radar_location  = [24.25413070088112, 54.55057856802998, 0.0] ## Lat, Long, Alt -- decimal degrees and meters

  range_data              = [3000.0, 400000.0]        ## [min, max] meters
  revolutions_per_minute  = 10.0                      ## RPM
  azimuth_width           = 7.0                       ## width of beam
  elevation_data          = [ 2.0, 45.0, 7.0, 5.0]    ## [min, max, width, rate]
  target_type             = /scud|cf/i                   ## only look for scud threats

  radars << RotatingRadar.new(  "SearchRadar_02",
                                radar_location, 
                                range_data, 
                                revolutions_per_minute, 
                                azimuth_width, 
                                elevation_data, 
                                target_type
                             ) ## take the defaults on range, elevation and RPM


=end

  #################
  ## SearchRadar_03
  ## Boresite: 0 deg
  ## Azimuth Min: 320 deg
  ## Azimuth Max: 80 deg
  ## Elevation Min: 5 deg
  ## Elevation Max: 60 deg
  ## Scan Pattern: Raster, 5 deg x 5 deg
=begin
  radar_location  = [24.33110253275136, 52.59954957745941, 0.0] ## Lat, Long, Alt -- decimal degrees and meters
  range_data      = [3000.0, 500000.0]             ## [min, max] meters
  azimuth_data    = [320.0, 80.0, 5.0, 5.0]        ## [min, max, width, rate] degrees and deg/sec
  elevation_data  = [  5.0, 60.0, 5.0, 5.0]        ## [min, max, width, rate] degrees and deg/sec
  target_type     = /icbm/i                        ## Only look for ICBM threats ("i" means case insensitive)


  radars << Radar.new(  "SearchRadar_03", 
                        radar_location, 
                        range_data, 
                        azimuth_data, 
                        elevation_data, 
                        target_type)

=end


  ##########################################
  ## Define Tracking Radars

  ###################
  ## TrackingRadar_01
  
  radar_location  = [25.27965317137238, 55.36665872621656, 0.0] ## Lat, Long, Alt -- decimal degrees and meters
  range_data      = [3000.0, 600000.0]    ## [min, max] meters

  radar_tracking_beam_width  = 4.0  ## SMELL: StkRadarDriver hardcodes 4 * this for searching beam width

  azimuth_data    = [45.0, radar_tracking_beam_width] ## [azimuth, width] degrees
  elevation_data  = [45.0, radar_tracking_beam_width] ## [elevation, width] degrees
  target_type     = /scud/i                        ## Only track ICBM threats or cf -- counter fire rockets
  
  radars << StaringRadar.new("TrackingRadar_01", radar_location, range_data, azimuth_data, elevation_data, target_type)


  ###################
  ## TrackingRadar_02
  
  radar_location  = [24.52813389622072, 55.01237880477231, 0.0] ## Lat, Long, Alt -- decimal degrees and meters
  range_data      = [3000.0, 600000.0]    ## [min, max] meters

  radar_tracking_beam_width  = 4.0  ## SMELL: StkRadarDriver hardcodes 4 * this for searching beam width

  azimuth_data    = [45.0, radar_tracking_beam_width] ## [azimuth, width] degrees
  elevation_data  = [45.0, radar_tracking_beam_width] ## [elevation, width] degrees
  target_type     = /scud/i                        ## Only track ICBM threats or cf -- counter fire rockets
  
  radars << StaringRadar.new("TrackingRadar_02", radar_location, range_data, azimuth_data, elevation_data, target_type)


  ###################
  ## TrackingRadar_03
  
  radar_location  = [24.26349789815201, 54.52815633385707, 0.0] ## Lat, Long, Alt -- decimal degrees and meters
  range_data      = [3000.0, 600000.0]    ## [min, max] meters

  radar_tracking_beam_width  = 4.0  ## SMELL: StkRadarDriver hardcodes 4 * this for searching beam width

  azimuth_data    = [45.0, radar_tracking_beam_width] ## [azimuth, width] degrees
  elevation_data  = [45.0, radar_tracking_beam_width] ## [elevation, width] degrees
  target_type     = /scud/i                        ## Only track ICBM threats or cf -- counter fire rockets
  
  radars << StaringRadar.new("TrackingRadar_03", radar_location, range_data, azimuth_data, elevation_data, target_type)
  
  
  return radars
  
end ## end of init_radars




## The End
##################################################################

