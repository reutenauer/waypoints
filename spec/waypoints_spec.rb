require 'spec_helper'

describe Waypoint do
  let(:waypoint) {
    Waypoint.new(
      timestamp: "2016-06-21T12:00:00.000Z",
      speed: 4,
      speed_limit: 6
    )
  }

  describe '.new' do
    it "instantiates a new Waypoint object" do
      waypoint = Waypoint.new
      expect(waypoint).to be_a Waypoint
    end

    it "defines a timestamp" do
      expect(waypoint.timestamp).to eq Time.utc(2016, 06, 21, 12, 0, 0)
    end

    it "defines a speed" do
      expect(waypoint.speed).to eq 4
    end

    it "defines a speed limit" do
      expect(waypoint.speed_limit).to eq 6
    end
  end

  describe '#interpolate' do
    it "interpolates the speed between two waypoints" do
      w0 = Waypoint.new(timestamp: '2016-07-21T12:00:00.000Z', speed: 6, speed_limit: 8)
      w1 = Waypoint.new(timestamp: '2016-07-21T12:00:04.000Z', speed: 10, speed_limit: 8)
      stats = w0.interpolate(w1)
      expect(stats.duration).to eq 2
    end

    it "returns 0 when interpolating between a waypoint and itself" do
      t = '2016-07-23T12:00:20.000Z'
      w = Waypoint.new(timestamp: t, speed: 15, speed_limit: 2)
      stats = w.interpolate(w)
      expect(stats.duration).to eq 0
      expect(stats.distance).to eq 0
    end

    it "returns 0 when two waypoints have the same timestamp" do
      t = '2016-07-23T12:00:25.000Z'
      w0 = Waypoint.new(timestamp: t, speed: 10, speed_limit: 5)
      w1 = Waypoint.new(timestamp: t, speed: 15, speed_limit: 5)
      stats = w0.interpolate(w1)
      expect(stats.duration).to eq 0
      expect(stats.distance).to eq 0
    end

    it "behaves correctly when acceleration is zero" do
      t0 = '2016-07-20T12:00:00.000Z'
      t1 = '2016-07-20T12:00:05.000Z'
      w0 = Waypoint.new(timestamp: t0, speed: 10, speed_limit: 5)
      w1 = Waypoint.new(timestamp: t1, speed: 10, speed_limit: 5)
      stats = w0.interpolate(w1)
      expect(stats.duration).to eq 5
      expect(stats.distance).to eq 50
    end
  end
end

describe SpeedingDataPoint do
  let(:spd) {
    SpeedingDataPoint.new(
      duration: 5,
      distance: 15,
      total_duration: 10,
      total_distance: 25
    )
  }

  describe ".new" do
    it "instantiates a new SpeedingDataPoint object" do
      spd = SpeedingDataPoint.new
      expect(spd).to be_a SpeedingDataPoint
    end

    it "defines a duration" do
      expect(spd.duration).to eq 5
    end

    it "defines a distance" do
      expect(spd.distance).to eq 15
    end

    it "defines a total duration" do
      expect(spd.total_duration).to eq 10
    end

    it "defines a total distance" do
      expect(spd.total_distance).to eq 25
    end
  end

  describe "#add_duration" do
    it "adds to the duration" do
      spd.add_duration(5)
      expect(spd.duration).to eq 10
    end
  end

  describe "#add_distance" do
    it "adds to the distance" do
      spd.add_distance(10)
      expect(spd.distance).to eq 25
    end
  end

  describe "#add_total_duration" do
    it "adds to the total duration" do
      spd.add_total_duration(15)
      expect(spd.total_duration).to eq 25
    end
  end

  describe "#add_total_distance" do
    it "adds to the total distance" do
      spd.add_total_distance(15)
      expect(spd.total_distance).to eq 40
    end
  end
end

describe InsuranceMapReduce do
  let(:waypoints) { InsuranceMapReduce.new }

  describe '.initialize' do
    it "instantiates a new object" do
      waypoints = InsuranceMapReduce.new
      expect(waypoints).to be_a InsuranceMapReduce
    end

    it "loads the data set" do
      waypoints = InsuranceMapReduce.new
      expect(waypoints.instance_variable_get(:@waypoints)).to be_an Array
    end
  end

  describe '#map' do
    it "computes the speeding data for each segment" do
      speeding_data = waypoints.map
      expect(speeding_data).to be_an Array
      expect(speeding_data.count).to eq 4
      expect(speeding_data.first).to be_a SpeedingDataPoint
      durations = speeding_data.map { |segment| segment.duration }
      expect(durations.map { |s| s.round(2) }).to eq [1.78, 5.00, 4.98, 0.0]
      distances = speeding_data.map { |segment| segment.distance }
      expect(distances.map { |d| d.round(2) }).to eq [15.75, 51.25, 48.4, 0.0]
      total_durations = speeding_data.map { |segment| segment.total_duration }
      expect(total_durations).to eq [5.0, 5.0, 5.0, 5.0]
      total_distances = speeding_data.map { |segment| segment.total_distance }
      expect(total_distances.first).to eq 39.47225
      expect(total_distances.last).to eq 41.625
    end
  end

  describe '#reduce' do
    it "collates the results over all segments" do
      summary = waypoints.reduce
      expect(summary).to be_a SpeedingDataPoint
      expect(summary.duration.round(2)).to eq 11.76
      expect(summary.distance.round(2)).to eq 115.4
      expect(summary.total_duration.round(2)).to eq 20.0
      expect(summary.total_distance.round(2)).to eq 180.9
    end
  end
end
