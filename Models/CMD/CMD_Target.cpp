////////////////////////////////////////////////////////////////////////////////
//
// Filename:         CMD_Target.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Hector Bayona
//                   Nancy Anderson
//					 Adel Klawitter
//
// Company Name:     Lockheed Martin
//                   Missiles & Fire Control
//                   Dallas, TX
//
// Revision History:
//
// <yyyymmdd> <Eng> <Description of modification>
//
////////////////////////////////////////////////////////////////////////////////

#define ISE_BUILD_DLL

#include "CMD_Target.h"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "Constants.hpp"
#include "DebugFlag.h"
#include "XMLWrapper.h"

#include <assert.h>
#include <cmath>
#include <sstream>
#include <string>

#include <iostream>
#include <boost/thread/thread.hpp>
#include <boost/thread/condition.hpp>
#include <boost/thread/xtime.hpp>

#include "osk/sim.h"
#include "msg/CMD_Event.h"
#include "msg/CMD_Stop.h"
#include "msg/CMD_TargetState.h"

using namespace std;

Sim *sim;

boost::mutex mutex;
boost::condition cmd_updated;
boost::condition ise_updated;

volatile bool waiting_for_ise=false;
volatile bool waiting_for_cmd=true;

template<class MODEL> class Surrogate : public MODEL
{
public:
	Surrogate(double x, double y, double vx, double vy) :
		MODEL(x, y, vx, vy)
	{
	}
	void init()
	{
		MODEL::init();
	}
	void update()
	{
		MODEL::update();
	}
	void rpt()
	{
		boost::mutex::scoped_lock lk(mutex);
		while (waiting_for_ise)
			ise_updated.wait(lk);
		waiting_for_ise=true;
		MODEL::rpt();
		waiting_for_cmd=false;
		cmd_updated.notify_one();
	}
private:
};

class Target : public Block
{
public:
	Target(double x, double y, double vx, double vy)
	{
		this->x = x;
		this->y = y;
		this->vx = vx;
		this->vy = vy;
		addIntegrator(this->x, this->vx);
		addIntegrator(this->y, this->vy);
	}
	void rpt()
	{
		//if( State::sample( 1.0) || State::tickfirst || State::ticklast) {
		printf("%12s %8.3f %8.3f %8.3f\n", "Target", State::t, x, y);
		//}
	}
	double x, y, vx, vy;
};

void run_cmd_side()
{
	sim->run();
}

//...................................................................................................
CMD_Target::CMD_Target()
{
}

//...................................................................................................
int CMD_Target::info(ACE_TCHAR **info_string, size_t length) const
{
	std::stringstream myinfo;
	myinfo << *this;

	if (*info_string == 0)
		*info_string = ACE::strnew(myinfo.str().c_str());
	else
		ACE_OS::strncpy(*info_string, myinfo.str().c_str(), length);

	return ACE_OS::strlen(*info_string) +1;
}

//...................................................................................................
ISE_Export ostream& operator<<(ostream& output, const CMD_Target& p)
{
	output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

	output << "CMD_Target:: ";
	output << " x: " << p.x;
	output << " y: " << p.y;
	output << " vx: " << p.vx;
	output << " vy: " << p.vy;
	return output;
}

//...................................................................................................
int CMD_Target::init(int argc, ACE_TCHAR *argv[])
{
	// setup the messages
	this->mSimStop = new CMD_Stop(); // receive
	MessageFunctor<CMD_Target> stopfunctor(this, &CMD_Target::processStop);
	mSimStop->subscribe(&stopfunctor, 0);

	mTgtState = new CMD_TargetState (); // send

	this->timing_.set(10); // 10Hz

	return this->SamsonModel::init(argc, argv);
}

#if 0
int CMD_Target::doTargetDestroyed (Samson_Peer::MessageBase *mb)
{
	this->destroyed = true;
	return 1;
}
#endif

//...................................................................................................
int CMD_Target::fini(void)
{
	delete mSimStop;
	delete mTgtState;
	return 1;
}

//...................................................................................................

Surrogate<Target> *target;
boost::thread *thrd1;

vector< vector<Block*> > vStage;
double tmax = 10.00;
double dt = 0.01;
double dts[] =
{ dt, dt };

int CMD_Target::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	x = 20.0;
	y = 5.0;
	vx = -1.0;
	vy = 0.0;
	stop = 0;

	target=new Surrogate<Target>( x, y, vx, vy);

	vector<Block*> vObj0;
	vObj0.push_back(target);

	vector<Block*> vObj1;
	vObj1.push_back(target);

	vStage.push_back(vObj0);
	vStage.push_back(vObj1);

	sim = new Sim( dts, tmax, vStage);

	thrd1=new boost::thread(&run_cmd_side);
	//boost::thread thrd1(&run_cmd_side);
	//boost::thread thrd2(&run_ise_side);
	mTgtState->x = target->x;
	mTgtState->y = target->y;
	mTgtState->vx = target->vx;
	mTgtState->vy = target->vy;
	mTgtState->publish(this->currFrame_, this->send_count_++);

	return 1;
}

int CMD_Target::MonteCarlo_Step(Samson_Peer::MessageBase *)
{
	boost::mutex::scoped_lock lk(mutex);
	if (State::ticklast)
		return 0;
	while (waiting_for_cmd)
		cmd_updated.wait(lk);
	waiting_for_cmd=true;
	this->toDB("CMD_Target");
	x = mTgtState->x = target->x;
	y = mTgtState->y = target->y;
	vx = mTgtState->vx = target->vx;
	vy = mTgtState->vy = target->vy;

	//cout<<"<--- (x,y): "<<mTgtState->x<<"  "<<mTgtState->y<<endl;
	mTgtState->publish(this->currFrame_, this->send_count_++);

	waiting_for_ise=false;
	ise_updated.notify_one();

	return 1;
}

int CMD_Target::MonteCarlo_EndRun(Samson_Peer::MessageBase *)
{
	thrd1->join();
	//thrd2.join();
	delete thrd1;
	delete sim;
	delete target;
	return 1;
}

int CMD_Target::processStop(Samson_Peer::MessageBase *)
{
	//const SamsonHeader *sh = mb->get_header();

	cout<<"*** Stop *** "<<mSimStop->stop<<endl;
	Sim::stop = mSimStop->stop;

	return 1;
}

//...................................................................................................
void CMD_Target::print(void)
{
	ACE_DEBUG((LM_INFO, "(%P|%t) CMD_Target at time %f (%f,%f) (%f,%f)\n",
			currTime_, x, y, vx, vy));
}

// Used by the service factory to create/destroy the model
ACE_FACTORY_DECLARE(ISE,CMD_Target)

