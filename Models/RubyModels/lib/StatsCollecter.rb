################################################################
###
##  File: StatsCollecter.rb
##  Desc: Basic tally keeper
##
##  A new stat item can be added at any time.  They do not all have to be
##  declared at initialization time.
##
##  Example Initialization:

require "observer"


=begin

$stats = StatsCollecter.new({   :total_missiles       => [0, "Total Red Missiles"],
                                :total_aircraft       => [0, "Total Red Aircraft"],
                                :total_threats        => [0, "Total Known Red Force Threats"],
                                :total_launchers      => [0, "Total Blue Force Launchers"],
                                :missile_engagements  => [0, "Total Inteceptor To Red Missile Pairings"],
                                :aircraft_engagements => [0, "Total Inteceptor To Red Aircraft Pairings"],
                                :missile_kills        => [0, "Total Red Missiles Killed"],
                                :aircraft_kills       => [0, "Total Red Aircraft Killed"],
                                :missile_leaks        => [0, "Total Red Missiles That Could Not Be Engaged"],
                                :aircraft_leaks       => [0, "Total Red Aircraft That Could Not Be Engaged"]
                             })

=end


class StatsCollecter

  include Observable

  attr_accessor :elements
  attr_accessor :valid

  #########################
  def initialize(a_hash={})

    @elements = a_hash
    @valid    = true

  end

  ############################
  def report(end_of_line="\n")

    a_str = ""

    @elements.each_pair do |thing, value|
      a_str << "#{thing} #{value[0]} \"#{value[1]}\"#{end_of_line}"
    end

    return a_str

  end

  ################################
  def count(thing=nil, how_many=1)
    return unless thing

    if @elements.include?(thing)
      @elements[thing][0] += how_many
    else
      @elements[thing] = [how_many, ""]
    end
    
    changed
    notify_observers(thing, @elements[thing])
    
  end

  ####################################
  def decrement(thing=nil, how_many=1)
    return unless thing

    if @elements.include?(thing)
      @elements[thing][0] -= how_many
    else
      @elements[thing] = [0 - how_many, ""]
    end

    changed
    notify_observers(thing, @elements[thing])

  end

  ###################################
  def set(thing, how_many=0, desc="")
    @elements[thing] = [how_many, desc]
    changed
    notify_observers(thing, @elements[thing])
  end

  ################################
  def describe(thing=nil, desc="")
    if thing
      @elements[thing][1] = desc
    else
      @elements[thing] = [0, desc]
    end
    changed
    notify_observers(thing, @elements[thing])
  end


  #########
  def reset
    @elements.each_key do |thing|
      @elements[thing][0] = 0
      changed
      notify_observers(thing, @elements[thing])
    end
  end

end ## end of class StatsCollecter



