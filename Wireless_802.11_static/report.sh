#!/bin/bash

in_name_list=("num_node" "num_flow" "num_packet_per_sec" "xmission_range")
out_name_list=("throughput" "average_delay" "pkt_delivery_ratio" "pkt_drop_ratio" "total_energy_consumption" "avg_energy_per_byte" "avg_energy_per_pkt")

if [ -e "Output" ]
then
	rm -r "Output"
fi
mkdir "Output"
if [ -e "Graph" ]
then
	rm -r "Graph"
fi
mkdir "Graph"

run()
{
	num_node=$1
	num_flow=$2
	num_packet_per_sec=$3
	xmission_range=$4
	seed=$5
	option=$6

	ns wireless_802.11_static.tcl $num_node $num_flow $num_packet_per_sec $xmission_range

	in_val_list=("$num_node" "$num_flow" "$num_packet_per_sec" "$xmission_range")
	output="$(awk -f measure.awk wireless_802.11_static-out.tr)"
	out_val_list=($output)
	j=$option
	for i in {0..6}
	do
		echo "${in_val_list[$j]} ${out_val_list[$i]}" >> "Output/"${out_name_list[$i]}"_vs_"${in_name_list[$j]}".dat"
	done
}

run_num_node()
{
	num_node_list=($1)
	n=$2
	num_flow=$3
	num_packet_per_sec=$4
	xmission_range=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run ${num_node_list[$i]} $num_flow $num_packet_per_sec $xmission_range $seed 0
	done
}

run_num_flow()
{
	num_node=$1
	num_flow_list=($2)
	n=$3
	num_packet_per_sec=$4
	xmission_range=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run $num_node ${num_flow_list[$i]} $num_packet_per_sec $xmission_range $seed 1
	done
}

run_num_packet_per_sec()
{
	num_node=$1
	num_flow=$2
	num_packet_per_sec_list=($3)
	n=$4
	xmission_range=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run $num_node $num_flow ${num_packet_per_sec_list[$i]} $xmission_range $seed 2
	done
}

run_xmission_range()
{
	num_node=$1
	num_flow=$2
	num_packet_per_sec=$3
	xmission_range_list=($4)
	n=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run $num_node $num_flow $num_packet_per_sec ${xmission_range_list[$i]} $seed 3
	done
}

run_num_node "10 20 30 40 50" 4 50 200 250 7
run_num_flow 20 "10 20 30 40 50" 4 200 250 7
run_num_packet_per_sec 20 50 "100 200 300 400 500" 4 250 7
run_xmission_range 20 50 200 "250 353 433 500 559" 4 7

#in_name_list=("num_node" "num_flow" "num_packet_per_sec" "xmission_range")
#out_name_list=("throughput" "average_delay" "pkt_delivery_ratio" "pkt_drop_ratio" "total_energy_consumption" "avg_energy_per_byte" "avg_energy_per_pkt")




gnuplot_command="set term png;"
for i in {0..3}
do
	for j in {0..6}
	do
		#gnuplot_command="$gnuplot_command"" set title \""${out_name_list[$j]}" vs "${in_name_list[$i]}"\" 0,0;"
		gnuplot_command="$gnuplot_command"" set output \"Graph/"${out_name_list[$j]}"_vs_"${in_name_list[$i]}".png\";"
		gnuplot_command="$gnuplot_command"" plot \"Output/"${out_name_list[$j]}"_vs_"${in_name_list[$i]}".dat\" with lines;"
	done
done

gnuplot -e "$gnuplot_command"
