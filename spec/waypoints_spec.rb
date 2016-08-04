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
    it "has a timestamp" do
      expect(waypoint.timestamp).to eq Time.utc(2016, 06, 21, 12, 0, 0)
    end

    it "has a speed" do
      expect(waypoint.speed).to eq 4
    end

    it "has a speed limit" do
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

    it "behaves correctly when acceleration is zero" do
      t0 = '2016-07-20T12:00:00.000Z'
      t1 = '2016-07-20T12:00:05.000Z'
      w0 = Waypoint.new(timestamp: t0, speed: 10, speed_limit: 5)
      w1 = Waypoint.new(timestamp: t1, speed: 10, speed_limit: 5)
      stats = w0.interpolate(w1)
      expect(stats.duration).to eq 5
      expect(stats.distance).to eq 50
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
  end
end

describe SpeedingDataPoint do
  let(:stats) { SpeedingDataPoint.new(duration: 5, distance: 15) }

  it "contains speeding data" do
    expect(stats.duration).to eq 5
    expect(stats.distance).to eq 15
  end

  describe "#add_duration" do
    it "adds to the duration" do
      stats.add_duration(5)
      expect(stats.duration).to eq 10
    end
  end

  describe "#add_distance" do
    it "adds to the distance" do
      stats.add_distance(10)
      expect(stats.distance).to eq 25
    end
  end
end

describe InsuranceMapReduce do
  let(:waypoints) { InsuranceMapReduce.new }

  describe '.initialize' do
    it "instantiates a new Waypoint object" do
      waypoints = InsuranceMapReduce.new
      expect(waypoints).to be_a InsuranceMapReduce
    end

    it "loads the data set" do
      waypoints = InsuranceMapReduce.new
      expect(waypoints.instance_variable_get(:@waypoints)).to be_an Array
    end
  end

  describe '#map' do
    it "maps over the segments" do
      speeding_data = waypoints.map
      expect(speeding_data).to be_an Array
      expect(speeding_data.count).to eq 4
      expect(speeding_data.first).to be_a SpeedingDataPoint
      durations = speeding_data.map { |segment| segment.duration }
      expect(durations.map { |s| s.round(2) }).to eq [1.78, 5.00, 4.98, 0.0]
      distances = speeding_data.map { |segment| segment.distance }
      expect(distances.map { |d| d.round(2) }).to eq [12.3, 51.25, 48.35, 0.0]
    end
  end

  describe '#reduce' do
    it "reduces the segments" do
      summary = waypoints.reduce
      expect(summary).to be_a SpeedingDataPoint
      expect(summary.duration.round(2)).to eq 11.76
      expect(summary.distance.round(2)).to eq 111.9
    end
  end
end
