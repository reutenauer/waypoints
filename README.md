# A solution to the Waypoints challenge

## Installation
This solution is written in Ruby.  It should be enough to have RSpec installed
and run `rspec` in the top-level directory (here) to see the main test cases;
if needed, a Gemfile is provided, so that one can run `bundle` to install the
appropriate dependencies.

The solution is the last entry in the spec file, that calls `#map` and
`#reduce` on the main class, with the data provided.  We find the following
results, rounded to two decimals:

  * Duration spent speeding: 11.76s
  * Distance covered while speeding: 115.40m
  * Total duration: 20s
  * Total distance covered: 180.9m

## How it works
I’ve taken the view that a linear interpolation of the speed between two
waypoints provides a sensible model, as the time elapsed between two
consecutive waypoints will usually be very short.  In this case the interval is
5 seconds, so it certainly fits the expectation.  The speed is thus given by
this graph:

![waypoints plot](theory/waypoints.png)

This is equivalent to saying that the acceleration *a* is constant between two
waypoints.  If we denote by *s*<sub>0</sub> and *t*<sub>0</sub> the speed and
time at the first waypoint, and *s*<sub>1</sub> and *t*<sub>1</sub> the speed
and time at the second one, the acceleration is the slope between these two
points:

  *a* = (*s*<sub>1</sub> - *s*<sub>0</sub>)
  / (*t*<sub>1</sub> - *t*<sub>0</sub>)

The speed at time *t* can thus in turn be expressed as

  *s*(*t*) = ∫<sub>*t*<sub>0</sub></sub>*a* d*t*
  = *a* × (*t* - *t*<sub>0</sub>) + *s*<sub>0</sub>

or alternatively, using the other waypoint as reference

  *s*(*t*) = ∫<sub>*t*<sub>1</sub></sub>*a* d*t*
  = *a* × (*t* - *t*<sub>1</sub>) + *s*<sub>1</sub>

If *s*<sub>0</sub> and *s*<sub>1</sub> are on different sides of the speed
limit *s*<sub>*ℓ*</sub>, the speed *s* will reach *s*<sub>*ℓ*</sub> at time
*t*<sub>*ℓ*</sub> such that

  *s*(*t*<sub>*ℓ*</sub>) = *s*<sub>*ℓ*</sub>
  ⇔ *a* × (*t*<sub>ℓ</sub> - *t*<sub>0</sub>) + *s*<sub>0</sub> = *s*<sub>*ℓ*</sub>
  ⇔ *t*<sub>ℓ</sub> - *t*<sub>0</sub> = (*s*<sub>*ℓ*</sub> - *s*<sub>0</sub>) / *a*
  ⇔ *t*<sub>ℓ</sub> = *t*<sub>0</sub> + (*s*<sub>*ℓ*</sub> - *s*<sub>0</sub>) / *a*

or, using the other waypoint:

*t*<sub>ℓ</sub> = *t*<sub>1</sub> + (*s*<sub>*ℓ*</sub> - s<sub>1</sub>) / *a*

This allows us to calculate for how long the driver was over the speed limit
(if at all).  In the code we use the variable *dur* to calculate the relative
duration rather than absolute times; this is what is interesting to us.

We also want to calculate the distance covered while speeding, this can again
be done by integrating:

  *dist* = ∫<sub>*t*<sub>*ℓ*</sub></sub>*s*(*t*) d*t*
  = ∫<sub>*t*<sub>*ℓ*</sub></sub>(*s*<sub>ℓ</sub> + *at*) d*t*
  = *s*<sub>*ℓ*</sub>(*t* - *t*<sub>*ℓ*</sub>) + *a* × (*t* - *t*<sub>*ℓ*</sub>)<sup>2</sup> / 2
  = (*s*<sub>*ℓ*</sub> + *a* × (*t* - *t*<sub>*ℓ*</sub>) / 2) × (*t* - *t*<sub>*ℓ*</sub>)

and at that point of the code *t* - *t*<sub>*ℓ*</sub> will be assigned to
*dur*, hence

  *dist* = (*s*<sub>*ℓ*</sub> + *a* × *dur* / 2) × *dur*

We have a similar formula for the total distance covered (regardless of whether
the driver was speeding or not).

The code needs to check that the correct conditions are fulfilled before
applying these formulæ, and the tests specify special cases that need to be
covered (when acceleration is 0, etc.)  One case that is not covered is when
the speed limit is different at both waypoints: in this case, the code will
return results that are possibly inconsistent.  This doesn’t however happen
with the data provided.
