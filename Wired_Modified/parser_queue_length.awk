BEGIN {
	qlen = 0;
	instq = "instant_queue_size.q";
	printf "" > instq;
}
{
	event = $1;
	time = $2;
	from_node = $3;
	to_node = $4;
	pkt_type = $5;
	pkt_size = $6;
	flags = $7;
	fid = $8;
	src_addr = $9;
	dst_addr = $10;
	seq_num = $11;
	pkt_id = $12;
	
	if (((from_node == node1 && to_node == node2) || (from_node == node2 && to_node == node1)) && event != "r") {
		if (event == "+") {
			qlen += pkt_size;
		} else if (event == "-" || event == "d") {
			qlen -= pkt_size;
		}
		printf "%f\t%f\n", time, qlen >> instq;
	}
}
END {
	
}