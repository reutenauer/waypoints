# A solution to the Waypoints challenge

## Installation
This solution is Written in Ruby.  It should be enough to have RSpec installed
and run `rspec` in the top-level directory (here) to see the main test cases;
if needed, a Gemfile is provided, so that one can run `bundle` to install the
appropriate dependencies.

The solution is the last entry in the spec file, that calls `#map` and
`#reduce` on the main class, with the data provided.

## How it works
I’ve taken the view that a linear interpolation of the speed between two
waypoints provides a sensible model, as the time elapsed between two
consecutive waypoints (5 seconds, in the data provided) will usually be very
short.  This is equivalent to saying that the acceleration is constant between
two waypoints, and the speed at any time can thus be calculated as

  s = a * (t - t<sub>0</sub>)<sup>2</sup> / 2

where a is the acceleration (s<sub>1</sub> - s<sub>0</sub>)
  / (t<sub>1</sub> - t<sub>0</sub>).
Care needs to be taken of the case where the acceleration is 0, and that is
what the code does; it also swaps both waypoints when the speed at waypoint 1
is lower than the one at waypoint 0, so that the acceleration is always
nonnegative.  This simplifies the reasoning when determining whether the driver
is above the speed limit or not.
