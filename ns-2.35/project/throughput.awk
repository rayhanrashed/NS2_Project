#!/usr/bin/awk -f
# calculate each class throughput(received, sent, lost)

BEGIN{
flag=0;
}

{
#r 0.241408 1 0 tcp 1040 ------- 1   4.0   0.0   3   6
#$1 $2     $3 $4 $5   $6   $7    $8    $9   $10  $11  $12
event = $1;
time = $2;
node_s = $3;
node_d = $4;
trace_type = $5;
pkt_size = $6;
classid = $8;

#eNB node id is 0
#aGW node id is 1
#server node id is 2
#UE node id >2
if(event == "-" && node_d >2 ) {
	if(flag==0) {
		start_time=time;
		flag=1;
	}
	end_time=time;
	ue_r_byte[classid] = ue_r_byte[classid] + pkt_size;
}
if(event == "+" && node_s >2 ) {
	ue_s_byte[classid]=ue_s_byte[classid]+pkt_size;
}
if(event == "d") {
	ue_d_byte[classid]=ue_d_byte[classid]+pkt_size;
}
}

END {      
	for(i=0;i<4;i++)
	{
		ue_r[i]=ue_r_byte[i]/1000000;
		ue_s[i]=ue_s_byte[i]/1000000;
		ue_d[i]=ue_d_byte[i]/1000000;
		total_r=total_r+ue_r[i];
		total_s=total_s+ue_s[i];
		total_d=total_d+ue_d[i];
	}
	printf("0\t1\t2\t3\ttotal(Mbyte)\n");
	printf("%1.2f\t%1.2f\t%1.2f\t%1.2f\t%1.2f\n",ue_r[0],ue_r[1],ue_r[2],ue_r[3],total_r);
	printf("%1.2f\t%1.2f\t%1.2f\t%1.2f\t%1.2f\n",ue_s[0],ue_s[1],ue_s[2],ue_s[3],total_s);
	printf("%1.2f\t%1.2f\t%1.2f\t%1.2f\t%1.2f\n",ue_d[0],ue_d[1],ue_d[2],ue_d[3],total_d);
}
