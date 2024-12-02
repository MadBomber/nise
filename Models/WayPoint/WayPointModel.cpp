/*
##############################################################
###
##  File: WayPointModel.cpp
#

Purpose:

  Fly a target from one way-point to another in a straight line
  at a constanct speed.

Input Data:

  A list of way-points that consists of four items:
    
    * Latitude
    * Longitude
    * Altitude
    * Speed (meters per second

Functional Description:

  Read a list of four-tuples.  Let A, B, and C be consecutive
  entries in the list such that A.position is the latitude,
  longitude and altitude.  A.speed is the 4th item of the tuple.
  
  The intitial condition is the target is locatione at A.position
  with an initial speed of A.speed.  The heading is from
  A.position toward B.position.
  
  Step the current position until B.position is reached.  Change
  current heading toward B.position.  Change speed to B.speed.
  
  When the last positoin in the list of tuples is reached, the
  model stops.

Details

  Additional details are located in the ISEwiki under the topic
  GenericWayPointModel.
*/


