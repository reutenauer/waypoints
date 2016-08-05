set terminal png truecolor
set output "waypoints.png"
set autoscale
set xdata time
set timefmt "%Y-%m-%dT%H:%M:%S.000Z"
set style data lines
plot "waypoints.txt" using 1:3 title "Speed limit", '' using 1:2 title "Speed of the vehicle"
