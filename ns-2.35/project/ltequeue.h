#ifndef ns_ltequeue_h
#define ns_ltequeue_h

#include "drop-tail.h"
//#include "drr.h"
#include "red.h"

//The flowing global variables are declared in ltequeue.cc. 
//extern int max_buf;
extern int flow[100];
extern int UE[100];
extern int eNB[100];
extern int cell[100];

class LTEQueue : public Queue {
public:
	LTEQueue() {
		bind_bool("qos_", &qos_);
		bind_bool("flow_control_", &flow_control_);
		bind_bool("HVQ_UE",&HVQ_UE);
		bind_bool("HVQ_eNB",&HVQ_eNB);
		bind_bool("HVQ_cell",&HVQ_cell);
		for(int i=0;i<100;i++)
		{
		//default is no flow control
			//flow[i]=0;
			UE[i]=-1;
			eNB[i]=-1;
			cell[i]=-1;
		}
	}
	~LTEQueue() {
	}
	void enque(Packet* p);
	Packet *deque();
protected:
	int qos_;
	int flow_control_;
	int HVQ_UE;
	int HVQ_eNB;
	int HVQ_cell;
};



#endif
