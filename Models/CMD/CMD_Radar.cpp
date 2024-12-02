////////////////////////////////////////////////////////////////////////////////
//
// Filename:         CMD_Radar.cpp
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

#include "CMD_Radar.h"
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
#include "msg/CMD_RadarState.h"
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
	} // Radar
	void init()
	{
		MODEL::init();
	}
	void update()
	{
		if (State::ready)
		{
			boost::mutex::scoped_lock lk(mutex);
			while (waiting_for_ise)
				ise_updated.wait(lk);
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
		MODEL::rpt();
	}
private:
};

class Radar : public Block
{
public:
	Radar(Target *target, double theta, double wn, double zeta)
	{
		x1 = theta / R;
		x2 = 0.0;
		this->wn = wn;
		this->zeta = zeta;
		this->target = target;
		addIntegrator(x1, x1d);
		addIntegrator(x2, x2d);
	}
	void update()
	{
		double theta_target = atan(target->y / target->x);
		theta_err = (theta_target - x1);
		//cout<<"(x,y): "<<target->x<<"  "<<target->y<<endl;
		//cout<<"(theta, err): "<<theta_target<<"  "<<theta_err<<endl;
		if (fabs(theta_err * R) < 1.0 && Sim::stop == 0)
		{
			Sim::stop = 1;
		}
		x1d = x2;
		x2d = theta_err * wn * wn - 2.0 * zeta * wn * x2;
	}
	void rpt()
	{
		//if( State::sample( 1.0) || State::tickfirst || State::ticklast) {
		printf("%12s %8.3f %8.3f\n", "Radar", State::t, theta_err * R);
		printf("\n");
		//}
	}
	double x1, x1d, x2, x2d, theta_err, wn, zeta;
	Target *target;
};

void run_cmd_side()
{
	sim->run();
}

//...................................................................................................
CMD_Radar::CMD_Radar()
{
}

//...................................................................................................
int CMD_Radar::info(ACE_TCHAR **info_string, size_t length) const
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
ostream& operator<<(ostream& output, const CMD_Radar& p)
{
	output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

	output << "CMD_Radar:: ";
	output << " stop: " << p.stop<<endl;
	return output;
}

//...................................................................................................
int CMD_Radar::init(int argc, ACE_TCHAR *argv[])
{
	// setup the messages
	this->mTgtState = new CMD_TargetState(); // receive
	MessageFunctor<CMD_Radar> srfunctor(this, &CMD_Radar::processTargetInput);
	mTgtState->subscribe(&srfunctor, 0);

	mSimStop = new CMD_Stop (); // send
	MessageFunctor<CMD_Radar> stopfunctor(this, &CMD_Radar::processStopInput);
	mSimStop->subscribe(&stopfunctor, 0);

	mSimStop = new CMD_Stop (); // send

	this->timing_.set(10); // 10Hz

	return this->SamsonModel::init(argc, argv);
}

#if 0
int CMD_Radar::doTargetDestroyed (Samson_Peer::MessageBase *mb)
{
	this->destroyed = true;
	return 1;
}
#endif

//...................................................................................................
int CMD_Radar::fini(void)
{
	delete mTgtState;
	delete mSimStop;
	return 1;
}

//...................................................................................................

Surrogate<Radar> *radar;
boost::thread *thrd1;

vector< vector<Block*> > vStage;
double tmax = 10.00;
double dt = 0.01;
double dts[] =
{ dt, dt };

int CMD_Radar::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	radar=new Surrogate<Radar>( &gTarget, 60.0, 2.643, 0.7);

	vector<Block*> vObj0;
	vObj0.push_back(radar);

	vector<Block*> vObj1;
	vObj1.push_back(radar);

	vStage.push_back(vObj0);
	vStage.push_back(vObj1);

	sim = new Sim( dts, tmax, vStage);

	thrd1=new boost::thread(&run_cmd_side);
	//boost::thread thrd1(&run_cmd_side);
	//boost::thread thrd2(&run_ise_side);

	return 1;
}

int CMD_Radar::MonteCarlo_Step(Samson_Peer::MessageBase *)
{
#if 0
	boost::mutex::scoped_lock lk(mutex);
	if(State::ticklast) return 0;
	while(waiting_for_cmd) cmd_updated.wait(lk);
	waiting_for_cmd=true;
	this->toDB("CMD_Radar");
	if(mSimStop->stop != Sim::stop)
	{
		mSimStop->stop = Sim::stop;
		mSimStop->publish(this->currFrame_, this->sendCount_++);
	}
	waiting_for_ise=false;
	ise_updated.notify_one();
#endif

	return 0;
}

int CMD_Radar::MonteCarlo_EndRun(Samson_Peer::MessageBase *)
{
	thrd1->join();
	//thrd2.join();
	delete thrd1;
	delete sim;
	delete radar;
	return 1;
}

int CMD_Radar::processTargetInput(Samson_Peer::MessageBase *)
{
	//const SamsonHeader *sh = mb->get_header();

	//cout<<"---> (x,y): "<<mTgtState->x<<"  "<<mTgtState->y<<endl;
	::gTarget.x = mTgtState->x;
	::gTarget.y = mTgtState->y;
	boost::mutex::scoped_lock lk(mutex);
	if (State::ticklast)
		return 0;
	while (waiting_for_cmd)
		cmd_updated.wait(lk);
	waiting_for_cmd=true;
	this->toDB("CMD_Radar");
	if (mSimStop->stop != Sim::stop)
	{
		mSimStop->t = State::t;
		mSimStop->stop = Sim::stop;
		mSimStop->publish(this->currFrame_, this->send_count_++);
	}
	waiting_for_ise=false;
	ise_updated.notify_one();
	this->sendEndFrame();

	return 1;
}

int CMD_Radar::processStopInput(Samson_Peer::MessageBase *)
{
	//::gTime   = mSimStop->t;
	Sim::stop = mSimStop->stop;
	//this->sendEndFrame ();
	return 1;
}

//...................................................................................................
void CMD_Radar::print(void)
{
	ACE_DEBUG((LM_INFO, "(%P|%t) CMD_Radar at time %f (%f,%f) (%f,%f)\n",
			currTime_, radar->x1, radar->x1d, radar->x2, radar->x2d));
}

// Used by the service factory to create/destroy the model
ACE_FACTORY_DECLARE(ISE,CMD_Radar)

