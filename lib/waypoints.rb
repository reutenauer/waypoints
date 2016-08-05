require 'json'
require 'time'

class Waypoint
  attr_reader :timestamp, :speed, :speed_limit

  def initialize(params = { })
    if params
      timestring = params[:timestamp] || params['timestamp']
      @timestamp = Time.parse(timestring) if timestring
      @speed = params[:speed] || params['speed']
      @speed_limit = params[:speed_limit] || params['speed_limit']
    end
  end

  def interpolate(other)
    s0 = speed
    s1 = other.speed
    s_l = speed_limit
    t0 = timestamp
    t1 = other.timestamp
    s0, s1 = s1, s0 if s0 > s1 # Ensure s0 < s1
    if s1 <= s_l
      SpeedingDataPoint.new(duration: 0, distance: 0)
    else
      if s0 == s1
        dur = t1 - t0
        distance = s0 * dur
      else
        if t0 == t1
          dur = 0
          distance = 0
        else
          acceleration = (s1 - s0) / (t1 - t0)
          s_l = s0 if s0 > s_l
          dur = (s1 - s_l) / acceleration
          distance = s_l * dur + acceleration * dur**2 / 2
        end
      end
      SpeedingDataPoint.new(duration: dur, distance: distance)
    end
  end
end

class SpeedingDataPoint
  attr_reader :duration, :distance

  def initialize(params = { })
    if params
      @duration = params[:duration] || params['duration']
      @distance = params[:distance] || params['distance']
    end
  end

  def add_duration(duration)
    @duration += duration
  end

  def add_distance(distance)
    @distance += distance
  end
end

class InsuranceMapReduce
  attr_reader :duration, :distance

  def initialize
    @waypoints =
    JSON::load(File.read(File.expand_path('../../data/waypoints.json', __FILE__))).map { |point| Waypoint.new(point) }
  end

  def map
    (@waypoints.count - 1).times.map do |i|
      @waypoints[i].interpolate(@waypoints[i + 1])
    end
  end

  def reduce
    summary = SpeedingDataPoint.new(duration: 0, distance: 0)
    map.each do |segment|
      summary.add_duration(segment.duration)
      summary.add_distance(segment.distance)
    end

    summary
  end
end
