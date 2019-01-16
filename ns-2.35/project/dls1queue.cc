#include "dls1queue.h"

extern int flow[100];
extern int UE[100];
extern int cell[100];
extern int eNB[100];

static class DLS1QueueClass : public TclClass {
public:
	DLS1QueueClass() : TclClass("Queue/LTEQueue/DLS1Queue") {}
	TclObject* create (int, const char*const*) {
		return (new DLS1Queue);
	}
} class_dls1queue;

void DLS1Timer::expire(Event*)
{
	//printf("enter DLS1Timer::expire\n");
	q_->resume();
}

void DLS1Queue::enque(Packet* p)
{
	hdr_ip *iph=HDR_IP(p);
	int classid=iph->flowid();
	//int daddr=iph->daddr();
	
	//printf("one packet of UE %d enter DLS1Queue::enque, class=%d\n",daddr, classid);

	if(qos_) {
		//classfication
		switch(classid){
			case 0: q0->enqueue(p);break;
			case 1: q1->enqueue(p);break;
			case 2: q2->enqueue(p);break;
			case 3: 
				{
					q3->enqueue(p);
					if(HVQ_eNB && q3->flowControl(3)==1)
					{
						printf("eNB is marked in DLS1Queue.\n");
						//Current model only one eNB is supported.
						eNB[0]=1; 
					}
					break;
				}
			default: 
				{
					printf("Invalid classid %d in DLS1Queue.\n",classid);
					exit(0);
				}
		}
	} else {//no qos_, no classification
		q0->enqueue(p);
	}	
}	

Packet* DLS1Queue::deque()
{
	if(!flow_control_) 
	{
		if(!qos_)
			return q0->dequeue();
	
		//if qos_ && !flow_control
		//scheduling: strict priority
		if(q0->length()>0)
		{
			return q0->dequeue();
		}
		if(q1->length()>0)
		{
			return q1->dequeue();
		}
		if(q2->length()>0)
		{
			//return q2->deque();
			return q2->dequeue();
		}
		if(q3->length()>0)
		{
			if(!HVQ_UE && !HVQ_eNB)
				return q3->dequeue();
			if(!HVQ_UE && HVQ_eNB) 
			{
				Packet* rp=q3->dequeue();
				if(q3->flowControl(3)==-1)
					eNB[0]=-1;
				return rp;
			}

			//with HVQ_UE
			for(int j=0;j<q3->length();j++)
			{
				Packet* rp=q3->find(j);
				if(!rp)
				{
					printf("Invalid rp in DLS1Queue.\n");	
					exit(0);
				}
				if(UE[HDR_IP(rp)->daddr()]==1)
				{
					printf("UE %d is blocked in DLS1Queue.\n",HDR_IP(rp)->daddr());
					continue;
				}
				q3->remove(rp);
				if(HVQ_eNB && q3->flowControl(3)==-1)
				{
					printf("eNB is demarked in DLS1Queue.\n");
					eNB[0]=-1;
				}
				return rp;
			}
		}
	
		if(q3->length()>0)
		{
			printf("All the UEs are blocked in DLS1Queue!\n");
			if(HVQ_UE) dls1timer.resched(0.1);	
		}
		if(q3->length()==0)
		{
			printf("All the UEs are empty in DLS1Queue!\n");
			if(HVQ_eNB) eNB[0]=-1;
		}
		return NULL;
	}

	/*
	//else flow control
	//flow control only valid to classo 2 & class 3
	if(!qos_)
	{
		for(int i=0; i < q0->length(); i++)
		{
			Packet *p=q0->find(i);
			hdr_ip *iph=HDR_IP(p);
			hdr_cmn *cmh=HDR_CMN(p);
			int size=cmh->size();
			int classid=iph->flowid();
			//int flowid=iph->daddr();

			if(classid==0 || classid==1)
			{
				q0->remove(p);
				return p;
			}
			//flow control only apply to class 2 and class 3
			if(size < flow[classid])
			{
				q0->remove(p);
				return p;
			}
			//else continue to find next packet
		}

		//no packet can be sent at the moment
		//either the q0 is NULL or q0 is blocked due to flow control
		if(q0->length()>0) {
			//try to send after 0.1 second
			dls1timer.resched(0.1);
		}
		return NULL;
	}

	//with flow control and QoS
	if(qos_)
	{
		if(q0->length()>0) {
			return q0->dequeue();
		}
		if(q1->length()>0) {
			return q1->dequeue();
		}
		for(int i=0;i < q2->length();i++) {
			Packet *p=q2->find(i);
			hdr_ip *iph=HDR_IP(p);
			hdr_cmn *cmh=HDR_CMN(p);
			int size=cmh->size();
			int classid=iph->flowid();
			//int flowid=iph->daddr();

			if(size<flow[classid])
			{
				q2->remove(p);
				return p;
			}
			//else continue to find next packet
		}
		
		//no packet can be sent in q2, try q3
		for(int i=0;i < q3->length();i++) {
			Packet *p=q3->find(i);
			hdr_ip *iph=HDR_IP(p);
			hdr_cmn *cmh=HDR_CMN(p);
			int size=cmh->size();
		//	int flowid=iph->daddr();
			int classid=iph->flowid();
			
			if(size<flow[classid])
			{
				q3->remove(p);
				return p;
			}
			//else continue to find next packet
		}
		// no packet can be sent in q3

		//no packet can be sent at the moment
		//either the all the queues are NULL or blocked due to flow control
		if(q2->length()>0 || q3->length()>0) {
			//try to send after 0.1 second
			dls1timer.resched(0.1);
		}
		return NULL;
	}
	*/
	return NULL;
}
