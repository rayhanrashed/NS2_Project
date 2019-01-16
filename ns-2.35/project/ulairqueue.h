#ifndef ns_ulairqueue_h
#define ns_ulairqueue_h

#include "ltequeue.h"

class ULAirQueue : public LTEQueue {
public:
	ULAirQueue(){
		q0=new DropTail;
		q1=new DropTail;
		q2=new DropTail;
		q3=new REDQueue("Drop");

                q0->setqlim(qlim_);
                q1->setqlim(qlim_);
                q2->setqlim(qlim_);
                q3->setqlim(qlim_);

		if(!qos_)
		{
			q0->setqlim(q0->limit()+q1->limit()+q2->limit()+q3->limit());
		}
	}
	~ULAirQueue() {
		delete q0;
		delete q1;
		delete q2;
		delete q3;
	}
	void enque(Packet* p);
	Packet* deque();	
protected:
	DropTail *q0;
	DropTail *q1;
	DropTail *q2;
	REDQueue *q3;
};

#endif
