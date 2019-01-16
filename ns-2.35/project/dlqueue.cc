#include "dlqueue.h"

extern int eNB[100];

static class DLQueueClass : public TclClass {
public:
	DLQueueClass() : TclClass("Queue/LTEQueue/DLQueue") {}
	TclObject* create (int, const char*const*) {
		return (new DLQueue);
	}
} class_dlqueue;

void DLTimer::expire(Event*)
{
	q_->resume();
}

void DLQueue::enque(Packet* p)
{
	hdr_ip *iph=HDR_IP(p);
	int classid=iph->flowid();

	if(qos_) {
		//classfication
		switch(classid){
			case 0: q0->enqueue(p);break;
			case 1: q1->enqueue(p);break;
			case 2: q2->enqueue(p);break;
			case 3: q3->enqueue(p);break;
			default: 
				{
					printf("invalid classid %d\n",classid);
					exit(0);
				}
		}
	} else {//no qos_, no classification
		q0->enqueue(p);
	}	
}	

Packet* DLQueue::deque()
{
	if(!qos_)
		return q0->dequeue();
	
	//else qos_ 
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
		if(!HVQ_eNB)return q3->dequeue();

		for(int j=0;j<q3->length();j++)
		{
			Packet* rp=q3->find(j);
			
			if(!rp)
			{
				printf("invalide rp in DLQueue.\n");
				exit(0);
			}
			
			//Current model only one eNB is supported.	
			if(eNB[0]==1)
			{
				printf("eNB is blocked in DLQueue.\n");
				dltimer.resched(0.01);	
				return NULL;
			}
				
			q3->remove(rp);
			return rp;
		}
	}
	
	//all the queues are empty.
	printf("DLQueue::deque(), all the queues are empty, no packet to be sent.\n");
	return NULL;
}
