#ifndef ns_dlairqueue_h
#define ns_dlairqueue_h

#include "ltequeue.h"
#include "timer-handler.h"

//extern int max_buf;
extern int flow[100];

class DLAirQueue;

class DLAirTimer : public TimerHandler {
public:
	DLAirTimer(DLAirQueue *q) : TimerHandler(){q_=q;}
protected:
	virtual void expire(Event* e);
	DLAirQueue *q_;
};

class DLAirQueue : public LTEQueue {
public:
	DLAirQueue():dlairtimer(this) {
		q0=new DropTail;
		q1=new DropTail;
		q2=new DropTail;
		q3=new REDQueue("Drop");

		q0->setqlim(qlim_);
		q1->setqlim(qlim_);
		q2->setqlim(qlim_);
		q3->setqlim(qlim_);

		bind("dnode_",&dnode_);

		if(!qos_)
		{
			q0->setqlim(q0->limit()+q1->limit()+q2->limit()+q3->limit());
		}
		
		if(flow_control_) {
			dlairtimer.sched(0.1);
			flow[0] = q0->limit() * q0->meanPacketSize();
			flow[1] = q0->limit() * q1->meanPacketSize();
			flow[2] = q0->limit() * q2->meanPacketSize();
			flow[3] = q0->limit() * q3->meanPacketSize();
		}
	}
	~DLAirQueue() {
		delete q0;
		delete q1;
		delete q2;
		delete q3;
	}

	void update();
	void enque(Packet* p);
	Packet* deque();
protected:
	int dnode_;
	DLAirTimer dlairtimer;
	DropTail *q0;//conversational traffic, class=0
	DropTail *q1;//streaming traffic, class=1
	//DRR q2;//interactive traffic, class=2
	DropTail *q2;//interactive traffic, class=2
	REDQueue *q3;//background traffic, class=3	
};

#endif
