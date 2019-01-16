BEGIN {
	start_time = 10000;
	end_time = 0;
	num_byte_received = 0;
	max_pkt_id = -1;
	min_pkt_id = 1000000;
	num_pkt_sent = 0;
	num_pkt_received = 0;
	num_pkt_forwarded = 0;
	num_pkt_dropped = 0;
	sum_delay = 0;
	
	max_num_node = 1000;
	for (i = 0; i < max_num_node; i++) {
		energy_consumption[i] = 0;
	}
}
{
	event = $1;
	time = $2;
	node = $3;
	type = $4;
	pkt_id = $6;
	pkt_type = $7;
	pkt_size = $8;
	energy = $13;
	total_energy = $14;
	idle_energy_consumption = $16;
	sleep_energy_consumption = $18;
	transmit_energy_consumption = $20;
	receive_energy_consumption = $22;
	
	sub(/^_*/, "", node);
	sub(/_*$/, "", node);
	if (energy == "[energy") {
		energy_consumption[node] = idle_energy_consumption + sleep_energy_consumption + transmit_energy_consumption + receive_energy_consumption;
	}
	if (pkt_type == "cbr" || pkt_type =="tcp") {
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
	total_energy_consumption = 0;
	for (i = 0; i < max_num_node; i++) {
		total_energy_consumption += energy_consumption[i];
	}
	avg_energy_per_byte = 0;
	if (num_byte_received > 0) {
		avg_energy_per_byte = total_energy_consumption / num_byte_received;
	}
	avg_energy_per_pkt = 0;
	if (num_pkt_received) {
		avg_energy_per_pkt = total_energy_consumption / num_pkt_received;
	}
	print throughput, avg_delay, pkt_delivery_ratio, pkt_drop_ratio, total_energy_consumption, avg_energy_per_byte, avg_energy_per_pkt;
}
