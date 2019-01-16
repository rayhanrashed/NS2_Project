#Set global variables
set num_node [lindex $argv 0]
set num_link [lindex $argv 1]
set num_packet_per_sec [lindex $argv 2]
set topo_file "topology"
set flow_file "flow"

#Create a simulator object
set ns_ [new Simulator]

#Open the nam trace file
set tracefd [open wired-out.tr w]
$ns_ trace-all $tracefd

#Open the nam trace file
set namtracefd [open wired-out.nam w]
$ns_ namtrace-all $namtracefd

set tq [open out.q w]

#Define a 'finish' procedure
proc finish {} {
	global ns_ tracefd namtracefd tq
	$ns_ flush-trace
	#Close the trace files
	close $tracefd
	close $namtracefd
	close $tq
	exit 0
}

proc attach-traffic {src_node dst_node} {
	global num_packet_per_sec
	
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
	$traffic attach-agent $src_agent
	$traffic set interval_ [expr 1.0 / $num_packet_per_sec]
	
	return $traffic
}

#Create all nodes
for {set i 0} {$i < $num_node} {incr i} {
	set node_($i) [$ns_ node]
}

#Create duplex links between the nodes using topo_file
set fd [open $topo_file r]
set lines [split [read $fd] "\n"]
close $fd
foreach line $lines {
    set index [split $line "\t"]
	set i [lindex $index 0]
	set j [lindex $index 1]
	if {[string length $i] > 0 && [string length $j] > 0} {
		$ns_ duplex-link $node_($i) $node_($j) 1Mb 100ms RED
	}
}

# Tracing a queue
set redq [[$ns_ link $node_(0) $node_(1)] queue]
$redq trace curq_
$redq trace ave_
$redq attach $tq

#Create flows using flow_file
set fd [open $flow_file r]
set lines [split [read $fd] "\n"]
close $fd
set time 0.5
foreach line $lines {
    set index [split $line "\t"]
	set src [lindex $index 0]
	set dst [lindex $index 1]
	if {[string length $src] > 0 && [string length $dst] > 0} {
		set traffic [attach-traffic $node_($src) $node_($dst)]
		$ns_ at $time "$traffic start"
		$ns_ at [expr {$time + 5}] "$traffic stop"
		set time [expr {$time + 0.5}]
	}
}

#Call the finish procedure after 5 seconds of simulation time
$ns_ at [expr {$time + 10}] "finish"

#Run the simulation
$ns_ run
