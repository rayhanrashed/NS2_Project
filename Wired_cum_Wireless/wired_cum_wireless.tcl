#Set global variables
set num_wireless_node 	10
set num_parallel_flow 	5
set num_cross_flow 		5
set num_random_flow 	10
set num_packet_per_sec 	400
set pkt_type 			1
set pkt_size 			28
set pkt_rate 			[expr $pkt_size * $num_packet_per_sec]b
set pkt_interval 		0.5
set num_row 			5 ;#number of row
set num_col 			[expr {int(ceil($num_wireless_node*1.0 / $num_row))}] ;#number of column
set node_arrangement 	"file" ;#"grid" or "random"
set x_dim 				600
set y_dim 				600
set start_time 			5.0
set stop_time 			100.0
set min_start_gap 		1
set max_start_gap 		5
set transmission_range	250
set node_movement_file	"scen.tcl"
set wired_topology		"topology"
set num_wired_node		2
set num_bs_node			2

#Define options
set val(chan)       Channel/WirelessChannel
set val(prop)       Propagation/TwoRayGround
set val(netif)      Phy/WirelessPhy
set val(mac)        Mac/802_11
set val(ifq)        Queue/DropTail/PriQueue
set val(ll)         LL
set val(ant)        Antenna/OmniAntenna
set val(x)              $x_dim			;# X dimension of the topography
set val(y)              $y_dim			;# Y dimension of the topography
set val(ifqlen)         50				;# max packet in ifq
set val(seed)           1.0
set val(adhocRouting)   DSDV
set val(nn)             [expr {$num_wireless_node + $num_bs_node}]		;# how many nodes are simulated
set val(stop)           $stop_time		;# simulation time

set val(energyModel)		EnergyModel
set val(idlePower)			1.0
set val(rxPower)			1.0
set val(txPower)			2.0
set val(sleepPower)			0.001
set val(transitionPower)	0.2
set val(transitionTime)		0.005
set val(initialEnergy)		150

#Create a simulator object
set ns_ [new Simulator]

# set up for hierarchical routing
$ns_ node-config -addressType hierarchical

AddrParams set domain_num_ [expr {1 + $num_bs_node}]           ;# number of domains
lappend cluster_num $num_wired_node              ;# number of clusters in each domain
for {set i 0} {$i < $num_bs_node} {incr i} {
	lappend cluster_num 1
}
AddrParams set cluster_num_ $cluster_num
set eilastlevel {}
for {set i 0} {$i < $num_wired_node} {incr i} {
	lappend eilastlevel 1
}
lappend eilastlevel [expr {1 + $num_wireless_node}]            ;# number of nodes in each cluster 
for {set i 1} {$i < $num_bs_node} {incr i} {
	lappend eilastlevel 1
}
AddrParams set nodes_num_ $eilastlevel ;# of each domain

#Open the trace file
set tracefd [open wired_cum_wireless-out.tr w]
$ns_ trace-all $tracefd

#Open the nam trace file
set namtracefd [open wired_cum_wireless-out.nam w]
$ns_ namtrace-all-wireless $namtracefd $val(x) $val(y)

#Setup topography object
set topo [new Topography]

#Define topology
$topo load_flatgrid $val(x) $val(y)

#Create God
set god_ [create-god $val(nn)]

#Transmission range
#              Pr * d^4 * L
#      Pt = ---------------------------
#             Gt * Gr * (ht^2 * hr^2)
#Where,
#Pt : Antenna power
#Pr : the received power and it is replaced with RxThresh_ whose value is 3.652 e-10
#Gt and Gr is the is the transmitter antenna gain and receiver antenna gain respectively
#ht and hr is the transmit antenna height and receive antenna height
#l: System loss
set Pr [Phy/WirelessPhy set RXThresh_]
set d $transmission_range
set L 1.0
set Gt 1
set Gr 1
set ht 1.5
set hr 1.5
#Calculate Pt from all parameters
proc calculate-Pt {} {
	global Pr Gt Gr ht hr L d
	set Pt [expr {($Pr * $d**4 * $L) / ($Gt * $Gr * $ht**2 * $hr**2)}]
	return $Pt
}
#Phy/WirelessPhy all values for 250m
#Phy/WirelessPhy set CPThresh_ 10.0
#Phy/WirelessPhy set CSThresh_ 3.65262e-10 ;#250m
#Phy/WirelessPhy set RXThresh_ 3.65262e-10 ;#250m
#Phy/WirelessPhy set Rb_ 2*1e6
#Phy/WirelessPhy set Pt_ 0.2818
#Phy/WirelessPhy set freq_ 914e+6
#Phy/WirelessPhy set L_ 1.0

#Define coverage
Phy/WirelessPhy set Pt_ [calculate-Pt]

#Create all wired nodes
for {set i 0} {$i < $num_wired_node} {incr i} {
	set W($i) [$ns_ node "0.$i.0"]
}

#Define how node should be created
$ns_ node-config -mobileIP ON \
                 -adhocRouting $val(adhocRouting) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
                 -channelType $val(chan) \
				 -topoInstance $topo \
                 -wiredRouting ON \
				 -agentTrace ON \
                 -routerTrace   ON \
                 -macTrace  OFF \
				 -movementTrace ON

#Create all base station nodes
for {set i 0} {$i < $num_bs_node} {incr i} {
	set BS($i) [$ns_ node "[expr {$i + 1}].0.0"]
	$BS($i) random-motion 0		;# disable random motion
	$BS($i) set X_ [expr {($i / 2 + 1) * 200}]
	$BS($i) set Y_ [expr {($i % 2 + 1) * 200}]
	puts "[$BS($i) set X_]"
	puts "[$BS($i) set Y_]"
}

$ns_ node-config -wiredRouting OFF

set node_(0) $W(0)
#Create all wireless nodes
for {set i 0} {$i < $num_wireless_node} {incr i} {
	set node_($i) [$ns_ node "1.0.[expr {$i + 1}]"]
	$node_($i) random-motion 0		;# disable random motion
	set HAaddress [AddrParams addr2id [$BS(0) node-addr]]
	[$node_($i) set regagent_] set home_agent_ $HAaddress
}

#Create duplex links between the nodes using topo_file
set fd [open $wired_topology r]
set lines [split [read $fd] "\n"]
close $fd
foreach line $lines {
    set index [split $line "\t"]
	set i [lindex $index 0]
	set j [lindex $index 1]
	if {[string length $i] > 0 && [string length $j] > 0} {
		$ns_ duplex-link $W($i) $W($j) 1Mb 100ms DropTail
	}
}

set rng [new RNG]
$rng seed $val(seed)

set u [new RandomVariable/Uniform]
$u set min_ 0
$u set max_ $num_wired_node
$u use-rng $rng
for {set i 0} {$i < $num_bs_node} {incr i} {
	$ns_ duplex-link $BS($i) $W([expr {int([$u value])}]) 1Mb 100ms DropTail
}

proc attach-traffic {src_node dst_node} {
	global num_packet_per_sec pkt_type pkt_size pkt_rate pkt_interval
	
	#Get instance of simulator
	set ns_ [Simulator instance]
	
	#Setup agent connection
	set src_agent [new Agent/UDP]
	$ns_ attach-agent $src_node $src_agent
	set dst_agent [new Agent/Null]
	$ns_ attach-agent $dst_node $dst_agent
	
	$ns_ connect $src_agent $dst_agent
	
	#Setup traffic over agent connection
	set traffic [new Application/Traffic/CBR]
	$traffic set type_ $pkt_type
	$traffic set packetSize_ $pkt_size
	$traffic set rate_ $pkt_rate
	$traffic set interval_ $pkt_interval
	$traffic attach-agent $src_agent
	
	return $traffic
}

#Create list of traffics
set traffic_list {}
set u [new RandomVariable/Uniform]
$u set min_ 0
$u set max_ $num_wired_node
$u use-rng $rng
set v [new RandomVariable/Uniform]
$v set min_ 0
$v set max_ $num_wireless_node
$v use-rng $rng
for {set i 0} {$i < $num_random_flow} {incr i} {
	set src_node $W([expr {int([$u value])}])
	set dst_node $node_([expr {int([$v value])}])
	lappend traffic_list [attach-traffic $src_node $dst_node]
}

source $node_movement_file

for {set i 0} {$i < $num_wireless_node} {incr i} {
	$node_($i) set X_ 200
	$node_($i) set Y_ 300
}

#Start all traffic
set dt [new RandomVariable/Uniform]
$dt set min_ $min_start_gap
$dt set max_ $max_start_gap
$dt use-rng $rng
set time $start_time
foreach traffic $traffic_list {
	$ns_ at $time "$traffic start"
	set time [expr {$time + [$dt value]}]
}

#Tell nodes when the simulation ends
for {set i 0} {$i < $num_wireless_node } {incr i} {
    $ns_ at $val(stop).0 "$node_($i) reset";
}

$ns_ at $val(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $val(stop).0001 "stop"
proc stop {} {
    global ns_ tracefd namtracefd
	$ns_ flush-trace
    close $tracefd
    close $namtracefd
}

#Run the simulation
puts "Starting Simulation..."
$ns_ run
