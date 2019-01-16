#include "dlairqueue.h"

//int max_buff=51200;
extern int flow[100];
extern int UE[100];

static class DLAirQueueClass : public TclClass {
public:
	DLAirQueueClass() : TclClass("Queue/LTEQueue/DLAirQueue") {}
	TclObject* create (int, const char*const*) {
		return (new DLAirQueue);
	}
} class_dlairqueue;

void DLAirTimer::expire(Event*)
{
	//q_->update();
}

void DLAirQueue::update()
{
	if(!qos_) {
		flow[0] = q0->limit()*q0->meanPacketSize() - q0->byteLength();
	} else {	
		flow[0] = q0->limit()*q0->meanPacketSize() - q0->byteLength();
		flow[1] = q1->limit()*q1->meanPacketSize() - q1->byteLength();
		flow[2] = q2->limit()*q2->meanPacketSize() - q2->byteLength();
		flow[3] = q3->limit()*q3->meanPacketSize() - q3->byteLength();
	}

	dlairtimer.resched(0.1);
}

void DLAirQueue::enque(Packet* p)
{
	hdr_ip *iph=HDR_IP(p);
	int classid=iph->flowid();
	int daddr=iph->daddr();

	if(qos_) {
		//classfication
		switch(classid){
			case 0: q0->enqueue(p);break;
			case 1: q1->enqueue(p);break;
			case 2: q2->enqueue(p);break;
			case 3: 
				{
					//HVQ_UE only affects to class 3 background traffic
					q3->enqueue(p);
					if(HVQ_UE && q3->flowControl(1)==1)
					{
						//mark flow control to this UE
						printf("UE %d is marked in DLAirQueue\n",daddr);
						UE[daddr]=1;
					}
					break;
				}
			default: 
				{
					printf("invalid classid %d in DLAirQueue\n",classid);
					exit(0);
				}
		}
	} else {//no qos_, no classification
		q0->enqueue(p);
	}	
}	

Packet* DLAirQueue::deque()
{
	if(!qos_)
	{
		return q0->dequeue();
	}	
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
		Packet *rp=q3->dequeue();

		if(!HVQ_UE) return rp;
		
		if(!rp)
		{
			UE[dnode_]=-1;
			printf("invalid rp in DLAirQueue\n");
			//printf("UE %d is demaked in DLAirQueue due to the rp.\n",dnode_);
			exit(0);
		}
		
		if(q3->flowControl(1)==-1)
		{
			printf("UE %d is demarked in DLAirQueue.\n",HDR_IP(rp)->daddr());
			UE[HDR_IP(rp)->daddr()]=-1;
		}

		return rp;
	}

	return NULL;
}
