// =================================================================
// =================================================================
#ifndef ROUTERSTATS_H
#define ROUTERSTATS_H

#include "ISE.h"

#include "DispatcherConfig.h"

#include <string>

#include "ace/Service_Config.h"
#include "ace/Thread_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

namespace Samson_Peer {

class RouteByteStats
{
public:
	RouteByteStats();
	void reset (void);
	void sample (size_t bytes);
	void compute(double &mean, double &stddev, int &total_bytes, int &total_msgs, double &delta_min, double &delta_max );
	void print (std::stringstream &, const char* const label, int type);
	void print_lastmsg (const char* const label);

private:
	enum { SAMPLE_SIZE=20 };

	int sample_length[SAMPLE_SIZE];
	int current_sample;

	unsigned int total_bytes;
	unsigned int total_msgs;
	double delta_sum;
	double delta_sq;
	double delta_min;
	double delta_max;
	unsigned int count;
	ACE_Time_Value last_time;
	ACE_Recursive_Thread_Mutex mutex_;
};



class RouteTimeStats
{
public:
	RouteTimeStats();
	void reset (void);
	void sample (double delta);
	void compute(int &count, double &mean, double &stddev, double &delta_min, double &delta_max );
private:
	double delta_sum;
	double delta_sq;
	double delta_min;
	double delta_max;
    unsigned int count;
	ACE_Recursive_Thread_Mutex mutex_;
};

}

#endif

