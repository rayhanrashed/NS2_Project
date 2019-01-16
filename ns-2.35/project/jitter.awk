#!/usr/bin/awk -f
#calculate each class jitter

BEGIN{
}

{
	event = $1;
      time = $2;
      node_s = $3;
      node_d = $4;
      trace_type = $5;
      pkt_size = $6;
      flag = $7;
	classid = $8
	pkt_id = $12;	
	
	if (event == "+" && node_s >1)
	{
		packet[pkt_id]=time;
	}
	if (event == "-" && ((node_d>1 && classid!=2) || (node_d>0 && classid==2)) ){
		if(packet[pkt_id]!=0){
			delay[classid,0] = time - packet[pkt_id];
			if(class[i]>0){
				if(delay[classid,0]>previous[classid])
					jitter[classid]=jitter[classid]+delay[classid,0]-previous[classid];
				if(delay[classid,0]<=previous[classid])
					jitter[classid]=jitter[classid]+previous[classid]-delay[classid,0];
			}
			if(class[i]==0){
				class[i]=class[i]+1;
			}
			previous[classid]=delay[classid,0];
			delay[classid,1] = delay[classid,1] + 1;
		}
	}
}

END {      
	for(classid=0;classid<4;classid++) {
		av_jitter[classid]=jitter[classid]/(delay[classid,1]-1);
		total[0] = total[0] + jitter[classid];
		total[1] = total[1] + delay[classid,1]-1;
	}
     	print "0		 1		 2		 3		 total";
	print av_jitter[0],"	",av_jitter[1],"	",av_jitter[2],"	",av_jitter[3],"	",total[0]/total[1];
}
