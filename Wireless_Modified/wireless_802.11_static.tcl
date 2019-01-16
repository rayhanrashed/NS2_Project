#Set global variables
set num_node 			[lindex $argv 0]
set num_parallel_flow 	0
set num_cross_flow 		0
set num_random_flow 	[lindex $argv 1]
set num_packet_per_sec 	[lindex $argv 2]
set pkt_type 			1
set pkt_size 			28
set pkt_rate 			[expr $pkt_size * $num_packet_per_sec]b
set pkt_interval 		0.5
set num_row 			[expr {int(floor($num_node**0.5))}] ;#number of row
set num_col 			[expr {int(ceil($num_node*1.0 / $num_row))}] ;#number of column
set node_arrangement 	"grid" ;#"grid" or "random"
set x_gap				200
set y_gap				200
set x_dim 				[expr {$x_gap * ($num_col + 1)}]
set y_dim 				[expr {$y_gap * ($num_row + 1)}]
set start_time 			5.0
set stop_time 			50.0
set min_start_gap 		1
set max_start_gap 		5
set transmission_range	[lindex $argv 3]


###################################################################


#Agent/TCP set windowOption_ 7


###################################################################

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
set val(nn)             $num_node		;# how many nodes are simulated
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

#Open the nam trace file
set tracefd [open wireless_802.11_static-out.tr w]
$ns_ trace-all $tracefd

#Open the nam trace file
set namtracefd [open wireless_802.11_static-out.nam w]
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

#Define how node should be created
$ns_ node-config -adhocRouting $val(adhocRouting) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
                 -channelType $val(chan) \
				 -topoInstance $topo \
				 -agentTrace ON \
                 -routerTrace   ON \
                 -macTrace  OFF \
				 -movementTrace ON \
				 -energyModel $val(energyModel) \
				 -idlePower $val(idlePower) \
				 -rxPower $val(rxPower) \
				 -txPower $val(txPower) \
          		 -sleepPower $val(sleepPower) \
          		 -transitionPower $val(transitionPower) \
          		 -transitionTime $val(transitionTime) \
				 -initialEnergy $val(initialEnergy)

proc attach-traffic {src_node dst_node} {
	global num_packet_per_sec pkt_type pkt_size pkt_rate pkt_interval
	
	#Get instance of simulator
	set ns_ [Simulator instance]
	
	#Setup agent connection
	set src_agent [new Agent/TCP]
	$ns_ attach-agent $src_node $src_agent
	set dst_agent [new Agent/TCPSink]
	$ns_ attach-agent $dst_node $dst_agent
	
	$ns_ connect $src_agent $dst_agent
	
	#Setup traffic over agent connection
	set traffic [new Application/Traffic/CBR]
	$traffic set type_ $pkt_type
	$traffic set packetSize_ $pkt_size
	$traffic set rate_ $pkt_rate
	#$traffic set interval_ $pkt_interval
	$traffic attach-agent $src_agent
	
	return $traffic
}

#Create all nodes
for {set i 0} {$i < $val(nn)} {incr i} {
	set node_($i) [$ns_ node]
	$node_($i) random-motion 0		;# disable random motion
}

set rng [new RNG]
$rng seed $val(seed)

#Create parallel flow
proc create-parallel-flow {num_flow} {
	global ns_ node_ num_node num_row num_col
	
	if {$num_flow > $num_row} {
		set num_flow $num_row
	}
	set traffic_list {}
	for {set i 0} {$i < $num_flow} {incr i} {
		set src [expr {$i * $num_col}]
		set dst [expr {$src + $num_col - 1}]
		if {$dst >= $num_node} {
			set dst [expr {$num_node - 1}]
		}
		set traffic [attach-traffic $node_($src) $node_($dst)]
		lappend traffic_list $traffic
	}
	return $traffic_list
}

#Create cross flow
proc create-cross-flow {num_flow} {
	global ns_ node_ num_node num_row num_col
	
	if {$num_flow > $num_col} {
		set num_flow $num_col
	}
	set traffic_list {}
	for {set i 0} {$i < $num_flow} {incr i} {
		set src $i
		set dst [expr {$src + ($num_row - 1) * $num_col}]
		if {$dst >= $num_node} {
			set dst [expr {$dst - $num_col}]
		}
		set traffic [attach-traffic $node_($src) $node_($dst)]
		lappend traffic_list $traffic
	}
	return $traffic_list
}

#Create random flow
proc create-random-flow {num_flow} {
	global ns_ node_ num_node rng
	
	set u [new RandomVariable/Uniform]
	$u set min_ 0
	$u set max_ [expr {$num_node - 1}]
	$u use-rng $rng

	set v [new RandomVariable/Uniform]
	$v set min_ 0
	$v set max_ [expr {$num_node - 2}]
	$v use-rng $rng

	set traffic_list {}
	for {set i 0} {$i < $num_flow} {incr i} {
		set src [expr {int([$u value])}]
		set dst [expr {(int([$v value]) + 1 + $src) % $num_node}]
		set traffic [attach-traffic $node_($src) $node_($dst)]
		lappend traffic_list $traffic
	}
	return $traffic_list
}

#Create list of traffics
set traffic_list {}
lappend traffic_list {*}[create-parallel-flow $num_parallel_flow]
lappend traffic_list {*}[create-cross-flow $num_cross_flow]
lappend traffic_list {*}[create-random-flow $num_random_flow]

#Define node initial position in nam
if {$node_arrangement == "grid"} {
	#Arrange nodes in grid
	set dx [expr {$val(x) / ($num_col + 1)}]
	set dy [expr {$val(y) / ($num_row + 1)}]
	for {set i 0} {$i < $num_node} {incr i} {
		set row [expr {$i / $num_col}]
		set col [expr {$i % $num_col}]
		$node_($i) set X_ [expr {($col + 1) * $dx}]
		$node_($i) set Y_ [expr {($row + 1) * $dy}]
		$node_($i) set Z_ 0
		$ns_ initial_node_pos $node_($i) 20
	}
} else {
	#Arrange nodes at random
	set x [new RandomVariable/Uniform]
	$x set min_ 0
	$x set max_ $val(x)
	$x use-rng $rng

	set y [new RandomVariable/Uniform]
	$y set min_ 0
	$y set max_ $val(y)
	$y use-rng $rng

	for {set i 0} {$i < $num_node} {incr i} {
		$node_($i) set X_ [$x value]
		$node_($i) set Y_ [$y value]
		$node_($i) set Z_ 0
		$ns_ initial_node_pos $node_($i) 20
	}
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
puts "$time"
#Tell nodes when the simulation ends
for {set i 0} {$i < $val(nn) } {incr i} {
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
