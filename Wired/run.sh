generateTopology="../Network_Generator/generateRandomTopology.exe" 
generateFlow="../Network_Generator/generateRandomFlow.exe" 
#./../Network_Generator/generateRandomTopology.exe topology 10 20
#./../Network_Generator/generateRandomFlow.exe flow 10 25
#ns wired.tcl 10 20 400
#nam wired-out.nam
awk -f parser.awk wired-out.tr 
 
#for per node throughput
#awk -v num_node=10 -f parser_with_per_node_throughput.awk wired-out.tr 
 
#for queue length between node1 and node2
#awk -v node1=0 -v node2=1 -f parser_queue_length.awk wired-out.tr 
#xgrapgh instant_queue_size.q 