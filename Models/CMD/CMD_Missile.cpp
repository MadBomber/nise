////////////////////////////////////////////////////////////////////////////////
//
// Filename:         CMD_Missile.cpp
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

#include "CMD_Missile.h"
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
//#include "msg/CMD_MissileState.h"
#include "msg/CMD_TargetState.h"
#include "msg/CMD_Stop.h"
#include "msg/CMD_Event.h"

using namespace std;

const double PI = 4.0 * atan( 1.0);
const double R = 180.0 / PI; // rad to deg conversion factor

struct Target
{
	double x, y;
} gTarget;

double gTime;

Sim *sim;

boost::mutex mutex;
boost::condition cmd_updated;
boost::condition ise_updated;

volatile bool waiting_for_ise=true;
volatile bool waiting_for_cmd=false;

template<class MODEL> class Surrogate : public MODEL
{
public:
	Surrogate(double x, double y, double vx, double vy) :
		MODEL(x, y, vx, vy)
	{
	} // Target
	Surrogate(Target *target, double theta, double wn, double zeta) :
		MODEL(target, theta, wn, zeta)
	{
		target->x=0;
		target->y=5;
	} // Missile
	Surrogate(Target *target, double x, double y, double vel, int init) :
		MODEL(target, x, y, vel), xo(x), yo(y), velo(vel)
	{
		if (init)
		{
			target->x=20;
			target->y=5;
		}
	} // Missile
	void init()
	{
		MODEL::init();
		State::t=::gTime+State::dtp;
		State::t1=State::t+State::dtp;
		this->x=xo;
		this->y=yo;
		this->vx=0.0;
		this->vy=0.0;
		this->vel=velo;
	}
	void update()
	{
		//cout<<"Update: "<<Sim::stop<<endl;
		if(Sim::stop==0)
		{
			State::t=0.0;
			return;
		}
#if 0
		first_time=false;
		this->x=xo;
		this->y=yo;
		this->vx=0.0;
		this->vy=0.0;
		this->vel=velo;
		return;
#endif
		//cout<<"uPdate: "<<Sim::stop<<endl;
		if(State::ready)
		{
			boost::mutex::scoped_lock lk(mutex);
			while(waiting_for_ise) ise_updated.wait(lk);
			waiting_for_ise=true;
			MODEL::update();
			waiting_for_cmd=false;
			cmd_updated.notify_one();
		}
		else
		{
			MODEL::update();
		}
	}
	void rpt()
	{
		if(Sim::stop==0) return;
		//cout<<"Rpt: "<<Sim::stop<<endl;
		MODEL::rpt();
	}
private:
	double xo, yo, velo;
};

class Missile : public Block
{
public:
	Missile(Target *target, double x, double y, double vel)
	{
		this->x = x;
		this->y = y;
		this->vel = vel;
		this->target = target;
		addIntegrator(this->x, vx);
		addIntegrator(this->y, vy);
		//cout<<"Missile(): "<<Sim::stop<<"  "<<this->x<<"  "<<this->y<<"  "<<this->vel<<endl;
	}
	void update()
	{
		//cout<<"update: "<<Sim::stop<<"  "<<this->x<<"  "<<this->y<<"  "<<this->vel<<endl;
		double dx = target->x - x;
		double dy = target->y - y;
		d = sqrt(dx * dx + dy * dy);
		vx = vel * (target->x - x) / d;
		vy = vel * (target->y - y) / d;
		//cout<<"update change: "<<Sim::stop<<"  "<<this->x<<"  "<<this->y<<"  "<<this->vel<<endl;
		if (d <= 0.1)
		{
			Sim::stop = -1;
		}
	}
	void rpt()
	{
		//cout<<"rpt: "<<Sim::stop<<endl;
		//if( State::sample( 1.0) || State::tickfirst || State::ticklast) {
		printf("%12s %8.3f %8.3f %8.3f %8.3f\n", "Missile", State::t, x, y, d);
		//}
	}
	double x, y, vx, vy, vel, d;
	Target *target;
};

void run_cmd_side()
{
	sim->run();
}

//...................................................................................................
CMD_Missile::CMD_Missile()
{
}

//...................................................................................................
int CMD_Missile::info(ACE_TCHAR **info_string, size_t length) const
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
ISE_Export ostream& operator<<(ostream& output, const CMD_Missile& p)
{
	output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

	output << "CMD_Missile:: ";
	output << " stop: " << p.stop<<endl;
	return output;
}

//...................................................................................................
int CMD_Missile::init(int argc, ACE_TCHAR *argv[])
{
	// setup the messages
	this->mTgtState = new CMD_TargetState(); // receive
	MessageFunctor<CMD_Missile> srfunctor(this,
			&CMD_Missile::processTargetInput);
	mTgtState->subscribe(&srfunctor, 0);

	mSimStop = new CMD_Stop (); // send
	MessageFunctor<CMD_Missile> stopfunctor(this,
			&CMD_Missile::processStopInput);
	mSimStop->subscribe(&stopfunctor, 0);

	this->timing_.set(10); // 10Hz

	return this->SamsonModel::init(argc, argv);
}

#if 0
int CMD_Missile::doTargetDestroyed (Samson_Peer::MessageBase *mb)
{
	this->destroyed = true;
	return 1;
}
#endif

//...................................................................................................
int CMD_Missile::fini(void)
{
	delete mTgtState;
	delete mSimStop;
	return 1;
}

//...................................................................................................

Surrogate<Missile> *missile;
boost::thread *thrd1;

vector< vector<Block*> > vStage;
double tmax = 10.00;
double dt = 0.01;
double dts[] =
{ dt, dt };

int CMD_Missile::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	missile=new Surrogate<Missile>( &gTarget, 0.0, 0.0, 2.0, 1);

	vector<Block*> vObj0;
	vObj0.push_back(missile);

	vector<Block*> vObj1;
	vObj1.push_back(missile);

	vStage.push_back(vObj0);
	vStage.push_back(vObj1);

	sim = new Sim( dts, tmax, vStage);

	thrd1=new boost::thread(&run_cmd_side);
	//boost::thread thrd1(&run_cmd_side);
	//boost::thread thrd2(&run_ise_side);

	return 1;
}

int CMD_Missile::MonteCarlo_Step(Samson_Peer::MessageBase *)
{
#if 0
	boost::mutex::scoped_lock lk(mutex);
	if(State::ticklast) return 0;
	while(waiting_for_cmd) cmd_updated.wait(lk);
	waiting_for_cmd=true;
	this->toDB("CMD_Missile");
	if(mSimStop->stop != Sim::stop)
	{
		mSimStop->stop = Sim::stop;
		mSimStop->publish(this->currFrame_, this->send_count_++);
	}
	waiting_for_ise=false;
	ise_updated.notify_one();
#endif

	return 1;
}

int CMD_Missile::MonteCarlo_EndRun(Samson_Peer::MessageBase *)
{
	thrd1->join();
	//thrd2.join();
	delete thrd1;
	delete sim;
	delete missile;
	return 1;
}

int CMD_Missile::processTargetInput(Samson_Peer::MessageBase *)
{
	//const SamsonHeader *sh = mb->get_header();

	//cout<<"---> (x,y): "<<mTgtState->x<<"  "<<mTgtState->y<<endl;
	::gTarget.x = mTgtState->x;
	::gTarget.y = mTgtState->y;
#if 1
	if (Sim::stop == 0)
		return 1;
	boost::mutex::scoped_lock lk(mutex);
	if (State::ticklast)
		return 0;
	while (waiting_for_cmd)
		cmd_updated.wait(lk);
	waiting_for_cmd=true;
	//this->toDB("CMD_Missile");
	if (mSimStop->stop != Sim::stop)
	{
		mSimStop->t =:: gTime;
		mSimStop->stop = Sim::stop;
		mSimStop->publish(this->currFrame_, this->send_count_++);
	}
	waiting_for_ise=false;
	ise_updated.notify_one();
#endif
	//        this->sendEndFrame ();

	return 1;
}

int CMD_Missile::processStopInput(Samson_Peer::MessageBase *)
{
::	gTime = mSimStop->t;
	Sim::stop = mSimStop->stop;
	//this->sendEndFrame ();
	return 1;
}

//...................................................................................................
void CMD_Missile::print(void)
{
	ACE_DEBUG((LM_INFO, "(%P|%t) CMD_Missile at time %f (%f,%f)\n", currTime_,
			missile->x, missile->y));
}

// Used by the service factory to create/destroy the model
ACE_FACTORY_DECLARE(ISE,CMD_Missile)

