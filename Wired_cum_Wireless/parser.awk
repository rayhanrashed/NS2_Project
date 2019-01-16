BEGIN {
	start_time = 10000;
	end_time = 0;
	num_byte_received = 0;
	max_pkt_id = -1;
	min_pkt_id = 0;
	num_pkt_sent = 0;
	num_pkt_received = 0;
	num_pkt_forwarded = 0;
	num_pkt_dropped = 0;
	sum_delay = 0;
}
{
	if (NF == 12) {
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
		
		if (pkt_type == "cbr") {
			if (time < start_time) {
				start_time = time;
			}
			if (time > end_time) {
				end_time = time;
			}
			if (event == "+" && pkt_id > max_pkt_id) {
				num_pkt_sent++;
				max_pkt_id = pkt_id;
				send_time[pkt_id] = time;
				recv_time[pkt_id] = -1;
			} else if (event == "r") {
				if (recv_time[pkt_id] < 0) {
					num_pkt_received++;
					recv_time[pkt_id] = time;
					sum_delay += recv_time[pkt_id] - send_time[pkt_id];
					num_byte_received += pkt_size;
				} else {
					sum_delay -= recv_time[pkt_id] - send_time[pkt_id];
					recv_time[pkt_id] = time;
					sum_delay += recv_time[pkt_id] - send_time[pkt_id];
				}
			} else if (event == "d") {
				num_pkt_dropped++;
				if (recv_time[pkt_id] >= 0) {
					num_pkt_received--;
					sum_delay -= recv_time[pkt_id] - send_time[pkt_id];
					num_byte_received -= pkt_size;
				}
			}
		}
	} else if (NF == 20) {
		event = $1;
		time = $2;
		node = $3;
		type = $4;
		pkt_id = $6;
		pkt_type = $7;
		pkt_size = $8;
		
		if (pkt_type == "cbr") {
			if (time < start_time) {
				start_time = time;
			}
			if (time > end_time) {
				end_time = time;
			}
			if (type == "AGT") {
				if (event == "s") {
					num_pkt_sent++;
					send_time[pkt_id] = time;
					recv_time[pkt_id] = -1;
				} else if (event == "r") {
					if (recv_time[pkt_id] < 0) {
						num_pkt_received++;
						recv_time[pkt_id] = time;
						sum_delay += recv_time[pkt_id] - send_time[pkt_id];
						num_byte_received += pkt_size;
					} else {
						sum_delay -= recv_time[pkt_id] - send_time[pkt_id];
						recv_time[pkt_id] = time;
						sum_delay += recv_time[pkt_id] - send_time[pkt_id];
					}
				} else if (event == "f") {
					num_pkt_forwarded++;
				}
			} else if (event == "D"){
				num_pkt_dropped++;
				if (recv_time[pkt_id] >= 0) {
					num_pkt_received--;
					sum_delay -= recv_time[pkt_id] - send_time[pkt_id];
					num_byte_received -= pkt_size;
				}
			}
		}
	} else if (NF == 17) {
		event = $1;
		time = $2;
		node = $3;
		type = $4;
		pkt_id = $6;
		pkt_type = $7;
		pkt_size = $8;
		
		if (pkt_type == "cbr") {
			if (time < start_time) {
				start_time = time;
			}
			if (time > end_time) {
				end_time = time;
			}
			if (type == "AGT") {
				if (event == "s") {
					num_pkt_sent++;
					send_time[pkt_id] = time;
				} else if (event == "r") {
					if (recv_time[pkt_id] < 0) {
						num_pkt_received++;
						recv_time[pkt_id] = time;
						sum_delay += recv_time[pkt_id] - send_time[pkt_id];
						num_byte_received += pkt_size;
					} else {
						sum_delay -= recv_time[pkt_id] - send_time[pkt_id];
						recv_time[pkt_id] = time;
						sum_delay += recv_time[pkt_id] - send_time[pkt_id];
					}
				} else if (event == "f") {
					num_pkt_forwarded++;
				}
			} else if (event == "D"){
				num_pkt_dropped++;
				if (recv_time[pkt_id] >= 0) {
					num_pkt_received--;
					sum_delay -= recv_time[pkt_id] - send_time[pkt_id];
					num_byte_received -= pkt_size;
				}
			}
		}
	}
}
END {
	run_time = end_time - start_time;
	throughput = 0;
	if (run_time > 0) {
		throughput = num_byte_received * 8.0 / run_time;
	}
	avg_delay = "Inf"
	if (num_pkt_received > 0) {
		avg_delay = sum_delay / num_pkt_received;
	}
	pkt_delivery_ratio = 0;
	pkt_drop_ratio = 1;
	if (num_pkt_sent > 0) {
		pkt_delivery_ratio = num_pkt_received / num_pkt_sent;
		pkt_drop_ratio = num_pkt_dropped / num_pkt_sent;
	}
	print "Throughput = " throughput;
	print "Average Delay = " avg_delay;
	print "Packet Delivery Ratio = " pkt_delivery_ratio;
	print "Packet Drop Ratio = " pkt_drop_ratio;
}