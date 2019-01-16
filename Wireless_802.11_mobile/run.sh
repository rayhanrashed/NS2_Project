#./../Network_Generator/setdest.exe -v 2 -n 25 -m 15 -M 15 -t 100 -x 600 -y 600 -p 5 > scen.tcl #
ns wireless_802.11_mobile.tcl; #tcl file
#nam wireless_802.11_mobile-out.nam
awk -f parser.awk wireless_802.11_mobile-out.tr