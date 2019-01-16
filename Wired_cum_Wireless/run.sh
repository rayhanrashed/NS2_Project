#./../Network_Generator/generateRandomTopology.exe topology 2 1
#./../Network_Generator/setdest.exe -v 2 -n 10 -m 15 -M 15 -t 100 -x 600 -y 600 -p 5 > scen.tcl #
ns wired_cum_wireless.tcl; #tcl file
#nam wired_cum_wireless-out.nam
awk -f parser.awk wired_cum_wireless-out.tr