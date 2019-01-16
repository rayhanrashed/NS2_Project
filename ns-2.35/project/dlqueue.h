#ifndef ns_dlqueue_h
#define ns_dlqueue_h

#include "ltequeue.h"
#include "timer-handler.h"

//extern int max_buf;
//extern int flow[100];

class DLQueue;

class DLTimer : public TimerHandler {
public: 
	DLTimer(DLQueue *q) : TimerHandler() {q_=q;}
protected:
	virtual void expire(Event* e);
	DLQueue *q_;
};

class DLQueue : public LTEQueue {
public:
	DLQueue():dltimer(this){
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
	~DLQueue(){
		delete q0;	
		delete q1;	
		delete q2;	
		delete q3;	
	}
	void enque(Packet* p);
	Packet* deque();
protected:
	DLTimer dltimer;
	DropTail *q0;//conversational traffic, class=0
	DropTail *q1;//streaming traffic, class=1
	//DRR q2;//interactive traffic, class=2
	DropTail *q2;//interactive traffic, class=2
	REDQueue *q3;//background traffic, class=3	
};

#endif
