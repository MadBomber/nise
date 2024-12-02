
#include <math.h>
#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>

#include "RouterStats.h"

namespace Samson_Peer {

// =================================================================
RouteByteStats::RouteByteStats()
{
	this->total_bytes = 0;
	this->total_msgs = 0;
	this->current_sample = 0;
	this->last_time = ACE_Time_Value::zero;

	this->reset();
}

// =================================================================
void
RouteByteStats::reset()
{
	delta_sum = 0.0;
	delta_sq = 0.0;
	delta_min = 0.0;
	delta_max = 0.0;
	count = 0;

	//current_sample = 0;
	//for(int i=0; i< RouteByteStats::SAMPLE_SIZE; i++) sample_length[i]=0;
}

// =================================================================
void
RouteByteStats::sample (size_t bytes)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	
	static bool first_call = true;
	
	this->total_bytes += bytes;

	this->sample_length[this->current_sample] = bytes;
	this->current_sample =(this->current_sample+1)%RouteByteStats::SAMPLE_SIZE;

	this->total_msgs++;
	ACE_Time_Value current(ACE_OS::gettimeofday());

	if (!first_call)
	{
		ACE_Time_Value tdelta = current - this->last_time;
		double tval = tdelta.usec()*1.0e-6;
		this->delta_sum += tval;
		this->delta_sq += tval*tval;
		
		if ( this->count++ > 1)
		{
			if (tval < this->delta_min) this->delta_min = tval;
			if (tval > this->delta_max) this->delta_max = tval;
		}
		else
		{
			this->delta_min = tval;
			this->delta_max = tval;
		}
	}
	else
		first_call = false;
			
	this->last_time = current;
}

// =================================================================
void 
RouteByteStats::compute(double &mean, double &stddev, int &total_bytes, int &total_msgs, double &delta_min, double &delta_max )
{
	//ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	
	mean = 0.0;
	stddev = 0.0;
	if ( this->count > 2 )
	{
		int theCount = this->count;
		mean =  this->delta_sum /  this->count;
		stddev = sqrt( (this->count*this->delta_sq -
			this->delta_sum*this->delta_sum)/
			theCount/
			(theCount-1)
		);
	}
	total_bytes = this->total_bytes;
	total_msgs = this->total_msgs;
	delta_min = this->delta_min;
	delta_max = this->delta_max;
}

// =================================================================
void
RouteByteStats::print (std::stringstream &my_report, const char* const label, int type)
{
	if ( type == 1 )
		this->print_lastmsg(label);
	else
	{
		//---------------------------------------------------------
		double mean = 0.0;
		double stddev = 0.0;
		if ( this->count > 2 )
		{
			int theCount = this->count;
			mean =  this->delta_sum /  this->count;
			stddev = sqrt( (this->count*this->delta_sq - this->delta_sum*this->delta_sum)/theCount/(theCount-1) );
		}

		//	"%8d %5d %8.3f %8.3f %6d %10.3g %10.3g (%s)",
		my_report 
			<< std::setw(8) << this->total_bytes/1024.0 << " "
			<< std::setw(5) << this->total_msgs << " "
			<< std::setw(8) << mean << " "
			<< std::setw(8) << stddev << " "
			<< std::setw(6) << this->count-1 << " "
			<< std::setw(10) << this->delta_min << " "
			<< std::setw(10) << this->delta_max << " "
			<< "(" << label << ")";
	}

    /*
	printf("\n\t( ");
	for(int i=RouteByteStats::SAMPLE_SIZE; i>0; i--)
    {
    	unsigned int ndx = (i+this->current_sample-1)%RouteByteStats::SAMPLE_SIZE;
		printf("%d ",this->sample_length[ndx]);
    }
    printf(")");
    */
}



// =================================================================
void
RouteByteStats::print_lastmsg (const char* const label)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	
	ACE_DEBUG ((LM_DEBUG,"\t[ "));
	for(int i=RouteByteStats::SAMPLE_SIZE; i>0; i--)
    {
    	unsigned int ndx = (i+this->current_sample-1)%RouteByteStats::SAMPLE_SIZE;
		ACE_DEBUG ((LM_DEBUG,"%d ",this->sample_length[ndx]));
    }
	ACE_DEBUG ((LM_DEBUG,"] (%s)",label));
}






// =================================================================
// =================================================================
// =================================================================
RouteTimeStats::RouteTimeStats()
{
	this->reset();
}

// =================================================================
void
RouteTimeStats::reset()
{
	this->delta_sum = 0.0;
	this->delta_sq = 0.0;
	this->delta_min = 3.0;
	this->delta_max = 0.0;
	this->count = 0;
}

// =================================================================
void
RouteTimeStats::sample (double delta)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	
	this->delta_sum += delta;
	this->delta_sq += delta*delta;
	
	if ( this->count++ > 1 )
	{
		if (delta < this->delta_min) this->delta_min = delta;
		if (delta > this->delta_max) this->delta_max = delta;
	}
	else
	{
		this->delta_min = delta;
		this->delta_max = delta;
	}
}

// =================================================================
void 
RouteTimeStats::compute(int &count, double &mean, double &stddev, double &delta_min, double &delta_max )
{
	mean = 0.0;
	stddev = 0.0;
	if ( this->count > 2 )
	{
		int theCount = this->count;
		mean =  this->delta_sum /  theCount;
		stddev = sqrt( (this->count*this->delta_sq -
			this->delta_sum*this->delta_sum)/
			theCount/
			(theCount-1)
		);
	}
	count = this->count;
	delta_min = this->delta_min;
	delta_max = this->delta_max;
}

} // namespace
