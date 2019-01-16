#include "uls1queue.h"

static class ULS1QueueClass : public TclClass {
public:
	ULS1QueueClass() : TclClass("Queue/LTEQueue/ULS1Queue"){}
	TclObject* create (int, const char*const*){
		return (new ULS1Queue);
	}
} class_uls1queue;

void ULS1Queue::enque(Packet* p)
{
	hdr_ip *iph=HDR_IP(p);
	int classid=iph->flowid();

	if(!qos_)
	{
		q0->enqueue(p);
		return;
	}
	
	//with QoS	
	switch(classid){
		case 0: q0->enqueue(p);break;
		case 1: q1->enqueue(p);break;
		case 2: q0->enqueue(p);break;
		case 3: q0->enqueue(p);break;
		defaut:
		{
			printf("invalid class id %d\n", classid);
			exit(0);
		}
	}
}

Packet* ULS1Queue::deque()
{
	if(!qos_)
		return q0->dequeue();

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
                return q2->dequeue();
        }
        if(q3->length()>0)
        {
                return q3->dequeue();
        }

	return NULL;
}
