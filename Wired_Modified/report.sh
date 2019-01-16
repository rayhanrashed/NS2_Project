#!/bin/bash
generateTopology="../Network_Generator/generateRandomTopology.out"
generateFlow="../Network_Generator/generateRandomFlow.out"

in_name_list=("num_node" "num_flow" "num_packet_per_sec")
out_name_list=("throughput" "average_delay" "pkt_delivery_ratio" "pkt_drop_ratio")

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
	num_link=$2
	num_flow=$3
	num_packet_per_sec=$4
	seed=$5
	option=$6
	
	./$generateTopology topology $num_node $num_link $seed
	./$generateFlow flow $num_node $num_flow $seed

	ns wired.tcl $num_node $num_link $num_packet_per_sec

	in_val_list=("$num_node" "$num_flow" "$num_packet_per_sec")
	output="$(awk -f measure.awk wired-out.tr)"
	out_val_list=($output)
	j=$option
	for i in {0..3}
	do
		echo "${in_val_list[$j]} ${out_val_list[$i]}" >> "Output/"${out_name_list[$i]}"_vs_"${in_name_list[$j]}".dat"
	done
}

run_num_node()
{
	num_node_list=($1)
	num_link_list=($2)
	n=$3
	num_flow=$4
	num_packet_per_sec=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run ${num_node_list[$i]} ${num_link_list[$i]} $num_flow $num_packet_per_sec $seed 0
	done
}

run_num_flow()
{
	num_node=$1
	num_link=$2
	num_flow_list=($3)
	n=$4
	num_packet_per_sec=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run $num_node $num_link ${num_flow_list[$i]} $num_packet_per_sec $seed 1
	done
}

run_num_packet_per_sec()
{
	num_node=$1
	num_link=$2
	num_flow=$3
	num_packet_per_sec_list=($4)
	n=$5
	seed=$6
	for i in $(seq 0 $n)
	do
		run $num_node $num_link $num_flow ${num_packet_per_sec_list[$i]} $seed 2
	done
}

run_num_node "10 20 30 40 50" "15 45 82 126 177" 4 50 200 7
run_num_flow 10 15 "10 20 30 40 50" 4 200 7
run_num_packet_per_sec 10 15 30 "100 200 300 400 500" 4 7

gnuplot_command="set term png;"
for i in {0..2}
do
	for j in {0..3}
	do
		gnuplot_command="$gnuplot_command"" set title \""${out_name_list[$j]}" vs "${in_name_list[$i]}"\";"
		gnuplot_command="$gnuplot_command"" set output \"Graph/"${out_name_list[$j]}"_vs_"${in_name_list[$i]}".png\";"
		gnuplot_command="$gnuplot_command"" plot \"Output/"${out_name_list[$j]}"_vs_"${in_name_list[$i]}".dat\" with lines;"
	done
done

gnuplot -e "$gnuplot_command"
