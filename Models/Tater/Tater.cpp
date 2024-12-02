////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Tater.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Tater Smith
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

#include "Tater.hpp"


int Tater::passTheTater(Samson_Peer::MessageBase *)
{
	this->callback_count_++;

	//if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::VERBOSE) ||
	//		Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::APB_DEBUG)  )
	{
		ACE_DEBUG((LM_DEBUG, "Tater::passTheTater() %d <-- (%d,%d) callbacks=%d of %d all=%d\n",
				this->unit_id_, msgTater->tater, msgTater->count,
				this->callback_count_, this->max_passes_ ,
				this->subscribe_all_taters_));
	}

	if (this->subscribe_all_taters_)
	{
		int subscribeTo = (this->unit_id_ != 1)? this->unit_id_-1 : this->max_taters_;
		if ( subscribeTo != msgTater->tater )
		{
			ACE_DEBUG((LM_DEBUG, "Tater::passTheTater() -> NOT FOR ME\n"));
			return 1;
		}
	}



	if ( this->callback_count_ == this->max_passes_  && this->unit_id_ == 1 )
	{
		ACE_DEBUG((LM_DEBUG, "Tater::passTheTater() FINAL %d <-- (%d,%d) (%d)\n", this->unit_id_, msgTater->tater, msgTater->count, this->callback_count_));
		this->stopSimulation();
	}
	else
	{
		msgTater->tater = this->unit_id_;
		msgTater->count = this->callback_count_ ;
		for( unsigned int i=0; i < this->payload_size; i++ ) {
			msgTater->payload[i] = 0;
		}
		msgTater->publish(0,0);
	}

	return 1;
}


int Tater::init(int argc, ACE_TCHAR *argv[])
{
	this->timer_.start ();

	// normally I would return here, but we are relying on  what this set up
	int retval = this->AppBase::init(argc,argv);

	ACE_Get_Opt get_opt (argc, argv, ACE_TEXT ("j:k:l:n:M:P:T"));

	// pull the number of models to control from the command line
	for (int c; (argc != 0) && ((c = get_opt ()) != -1); )
	{
		switch (c)
		{
		case 'n':
			this->max_taters_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;

		case 'M':
			this->max_passes_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;

		case 'P':
			this->payload_size = ACE_OS::atoi (get_opt.opt_arg ());
			break;

		case 'T':
			this->subscribe_all_taters_ = true;
			break;
		}
	}
	ACE_DEBUG ((LM_DEBUG, "Tater::init() %d of %d with %d passes, subscribe to %s, ~msg size = %d\n",
			this->unit_id_,  this->max_taters_, this->max_passes_,
			this->subscribe_all_taters_?"ALL":"ONE", this->payload_size ));


	int subscribeTo = 0;
	if ( !this->subscribe_all_taters_ )
	{
		subscribeTo = (this->unit_id_ != 1)? this->unit_id_-1 : this->max_taters_;
	}

	msgTater = auto_ptr<TaterMsg>(new TaterMsg(payload_size));
	MessageFunctor<Tater> passTheTaterFunctor(this,&Tater::passTheTater);
	msgTater->subscribe(&passTheTaterFunctor,subscribeTo);

	this->callback_count_=0;


	if(this->unit_id_==1) {
		// Become the Job Master
		Samson_Peer::SAMSON_OBJMGR::instance ()->setRunMaster ();

		// Fill the PeerTable
		int ntaters = Samson_Peer::SAMSON_OBJMGR::instance ()->getPeerTable (run_id_,peer_table);
		if ( ntaters != this->max_taters_ )
		{
			ACE_DEBUG ((LM_DEBUG, "Tater::init() %d != %d \n", ntaters,  this->max_taters_));
		}

		// all the other Taters to come alive
		this->initWaitForAll();
	}

	return retval;
}

//...................................................
int Tater::fini(void)
{
	ACE_DEBUG((LM_DEBUG, "Tater::fini() %d called %d\n", this->unit_id_, this->callback_count_));

	this->timer_.stop ();
	ACE_Time_Value measured;
	this->timer_.elapsed_time (measured);
	double interval_sec = measured.msec () / 1000.0;
	ACE_DEBUG((LM_DEBUG,"Execution time %f\n", interval_sec));
	return 1;
}


//...................................................
int Tater::handle_timeout (const ACE_Time_Value &, const void *)
{
	ACE_TRACE("Tater::handle_timeout");

	(this->*timeout_action)();

	// Must return a zero to continue
	return 0;
}


//...................................................
// Called every three seconds until all the Taters have reported in
int Tater::initWaitForAll(void)
{
	if ( !Samson_Peer::SAMSON_OBJMGR::instance ()->checkPeersStarted (peer_table) )
	{
		ACE_Time_Value const next_time (3);

		// call ME back on the timeout
		this->timeout_action = &Tater::initWaitForAll;

		if (ACE_Reactor::instance ()->schedule_timer (this, 0, next_time) == -1)
			ACE_ERROR ((LM_ERROR, ACE_TEXT ("(%P|%t) %p\n"), ACE_TEXT ("schedule_timer")));
		else
			ACE_DEBUG ((LM_INFO, ACE_TEXT ("(%P|%t) Tater::initWaitForAll -> Scheduling timer, waiting for processes to start...\n")));
	}
	else //start the passing the tater
	{
		ACE_DEBUG ((LM_INFO, ACE_TEXT ("(%P|%t) Tater::initWaitForAll -> Start Passing the Hot Potato. (%d,%d)\n"),
				this->unit_id_,this->callback_count_));
		msgTater->tater = this->unit_id_;
		msgTater->count = 0;
		for( unsigned int i=0; i < this->payload_size; i++ ) {
			msgTater->payload.push_back(i);
		}
		msgTater->publish(0,0);
	}
	return 1;
}

ACE_FACTORY_DECLARE(ISE,Tater)

