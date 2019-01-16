#include "ltequeue.h"

//int max_buff=51200;

int flow[100];
int UE[100];
int eNB[100];
int cell[100];

static class LTEQueueClass : public TclClass {
public:
	LTEQueueClass() : TclClass("Queue/LTEQueue") {}
	TclObject* create (int, const char*const*) {
		return (new LTEQueue);
	}
} class_ltequeue;

//Define the empty functions here to avoid the compilation error.
void LTEQueue::enque(Packet *p)
{
}

Packet* LTEQueue::deque()
{
}
