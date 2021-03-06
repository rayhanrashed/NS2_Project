# for "warning: no class variable Session/RTP::debug_"
Session/RTP set debug_ 0

# Define the multicast mechanism
set ns [new Simulator -multicast on]

# Predefine tracing
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# Set the number of subscribers
set number 10

# qos_ means whether classfication/scheduling mechanism is used
#Queue/LTEQueue set qos_ true 
# flow_control_ is used in the model phase
Queue/LTEQueue set flow_control_ false
# later HVQ flow control mechanism is used
#Queue/LTEQueue set HVQ_UE true 
#Queue/LTEQueue set HVQ_eNB false 
#Queue/LTEQueue set HVQ_cell false 

# Define the LTE topology
# UE(i) <--> eNB <--> aGW <--> server
# Other configuration parameters see ~ns/tcl/lib/ns-default.tcl

# step 1: define the nodes, the order is fixed!!
set eNB [$ns node];		# node id is 0
set aGW [$ns node];		# node id is 1
set server [$ns node];	# node id is 2
for { set i 0} {$i < $number} {incr i} {
	set UE($i) [$ns node];	# node id is > 2
}

# step 2: define the links to connect the nodes
for { set i 0} {$i < $number} {incr i} {
	$ns simplex-link $UE($i) $eNB 500Mb 2ms LTEQueue/ULAirQueue
	$ns simplex-link $eNB $UE($i) 1Gb 2ms LTEQueue/DLAirQueue
}

$ns simplex-link $eNB $aGW 5Gb 10ms LTEQueue/ULS1Queue
$ns simplex-link $aGW $eNB 5Gb 10ms LTEQueue/DLS1Queue

# The bandwidth between aGW and server is not the bottleneck.
$ns duplex-link $aGW $server 10Gb 100ms DropTail

# step 3: define the traffic, based on  TR23.107 QoS concept and architecture
#    class id	class type	simulation application	
#    -------------------------------------------------
#    0: 	Conversational: Session/RTP/RTPAgent
#    1: 	Streaming: 	CBR/UdpAgent
#    2: 	Interactive: 	HTTP/TcpAgent (HTTP/Client, HTTP/Cache, HTTP/Server)
#    3: 	Background: 	FTP/TcpAgent

# step 3.1 define the conversational traffic
set mproto DM
set mrthandle [$ns mrtproto $mproto {}]
set group [Node allocaddr]

for { set i 0 } { $i < $number } {incr i} {
	set s0($i) [new Session/RTP]
	set s1($i) [new Session/RTP]
	# Adaptive Multi-Rate call bit rates: 
	# AMR: 12.2, 10.2, 7.95, 7.40, 6.70, 5.90, 5.15 and 4.75 kb/s
	$s0($i) session_bw 12.2kb/s
	$s1($i) session_bw 12.2kb/s
	$s0($i) attach-node $UE($i)
	$s1($i) attach-node $server
	$ns at 0.7 "$s0($i) join-group $group"
	$ns at 0.8 "$s0($i) start"
	$ns at 0.9 "$s0($i) transmit 12.2kb/s"
	$ns at 1.0 "$s1($i) join-group $group"
	$ns at 1.1 "$s1($i) start"
	$ns at 1.2 "$s1($i) transmit 12.2kb/s"
}

# step 3.2 define the streaming traffic
for { set i 0} {$i < $number} {incr i} {
	set udp($i) [new Agent/UDP]
	$ns attach-agent $server $udp($i)
	set null($i) [new Agent/Null]
	$ns attach-agent $UE($i) $null($i)
	$ns connect $udp($i) $null($i)
	$udp($i) set class_ 1

	set cbr($i) [new Application/Traffic/CBR]
	$cbr($i) attach-agent $udp($i)
	$cbr($i) set packetSize_ 1000
	$cbr($i) set rate_ 0.01Mb
	$cbr($i) set random_ false
	$ns at 1.4 "$cbr($i) start"
	#$ns at 40.0 "$cbr($i) stop"
}

# step 3.3 define the interactive traffic
$ns rtproto Session
set log [open "http.log" w]

# Care must be taken to make sure that every client sees the same set of pages as the servers to which they are attached.
set pgp [new PagePool/Math]
set tmp [new RandomVariable/Constant] ;# Size generator
$tmp set val_ 10240 ;# average page size
$pgp ranvar-size $tmp
set tmp [new RandomVariable/Exponential] ;# Age generator
$tmp set avg_ 4 ;# average page age
$pgp ranvar-age $tmp

set s [new Http/Server $ns $server]
$s set-page-generator $pgp
$s log $log

set cache [new Http/Cache $ns $aGW]
$cache log $log

for { set i 0} {$i<$number} {incr i} {
	set c($i) [new Http/Client $ns $UE($i)]
	set ctmp($i) [new RandomVariable/Exponential] ;# Poisson process
	$ctmp($i) set avg_ 1 ;# average request interval
	$c($i) set-interval-generator $ctmp($i)
	$c($i) set-page-generator $pgp
	$c($i) log $log
}

$ns at 0.4 "start-connection"
proc start-connection {} {
	global ns s cache c number

	$cache connect $s
	for { set i 0} {$i<$number} {incr i} {
		$c($i) connect $cache
		$c($i) start-session $cache $s
	}
}

# step 3.4 define the background traffic
# no parameters to be configured by FTP
# we can configue TCP and TCPSink parameters here.
for { set i 0} {$i < $number} {incr i} {
	set tcp($i) [new Agent/TCP]
	$ns attach-agent $server $tcp($i)
	set sink($i) [new Agent/TCPSink]
	$ns attach-agent $UE($i) $sink($i)
	$ns connect $tcp($i) $sink($i)
	$tcp($i) set class_ 3
	$tcp($i) set packetSize_ 0.5M

	set ftp($i) [new Application/FTP]
	$ftp($i) attach-agent $tcp($i)
	$ns at 3.4 "$ftp($i) start";# time 0.4
}

# finish tracing
$ns at 30 "finish"
proc finish {} {
	global ns f nf
	#global ns f nf log
	$ns flush-trace
	#flush $log
	#close $log
	close $f
	close $nf
	puts "running nam..."
	exec nam out.nam &
	exit 0
}

# Finally, start the simulation.
$ns run
