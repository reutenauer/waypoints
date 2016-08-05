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
      dur = 0
      distance = 0

      total_duration = t1 - t0
      if total_duration == 0
        total_distance = 0
      else
        a = (s1 - s0) / total_duration
        total_distance = s0 * total_duration + a * total_duration**2 / 2
      end
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
          total_distance = s0 * (t1 - t0) + acceleration * (t1 - t0)**2 / 2
        end
      end
    end

  SpeedingDataPoint.new(duration: dur, distance: distance,
    total_duration: t1 - t0, total_distance: total_distance)
  end
end

class SpeedingDataPoint
  attr_reader :duration, :distance, :total_duration, :total_distance

  def initialize(params = { })
    if params
      @duration = params[:duration] || params['duration']
      @distance = params[:distance] || params['distance']
      @total_duration = params[:total_duration] || params['total_duration']
      @total_distance = params[:total_distance] || params['total_distance']
    end
  end

  def add_duration(duration)
    @duration += duration
  end

  def add_distance(distance)
    @distance += distance
  end

  def add_total_duration(total_duration)
    @total_duration += total_duration
  end

  def add_total_distance(total_distance)
    @total_distance += total_distance
  end
end

class InsuranceMapReduce
  attr_reader :duration, :distance

  def initialize
    data_file = File.expand_path('../../data/waypoints.json', __FILE__)
    @waypoints = JSON::load(File.read(data_file)).map do |point|
      Waypoint.new(point)
    end
  end

  def map
    (@waypoints.count - 1).times.map do |i|
      @waypoints[i].interpolate(@waypoints[i + 1])
    end
  end

  def reduce
    summary = SpeedingDataPoint.new(duration: 0, distance: 0,
      total_duration: 0, total_distance: 0)
    map.each do |segment|
      summary.add_duration(segment.duration)
      summary.add_distance(segment.distance)
      summary.add_total_duration(segment.total_duration)
      summary.add_total_distance(segment.total_distance)
    end

    summary
  end
end
