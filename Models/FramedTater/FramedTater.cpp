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

#include "FramedTater.hpp"

int FramedTater::passTheTater(Samson_Peer::MessageBase *)
{
		this->callback_count_++;


		//if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::VERBOSE) ||
		//		Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::APB_DEBUG)  )
		{
			ACE_DEBUG((LM_DEBUG, "FramedTater::passTheTater() %d <-- (%d,%d,%d,%c) (%d,%d,%c)\n", this->unit_id_,
					msgTater->tater, msgTater->cb_count, msgTater->fr_count, (msgTater->inFrame?'T':'F'),
					this->callback_count_, this->frame_count_, (this->inFrame_?'T':'F') ));
		}


		if ( this->callback_count_ >= this->max_passes_  && this->unit_id_ == 1 )
		{
			ACE_DEBUG((LM_DEBUG, "FramedTater::passTheTater() FINAL %d <-- (%d,%d) (%d)\n", this->unit_id_, msgTater->tater, msgTater->cb_count, this->callback_count_));
			this->sendEndCase();
		}
		else if ( this->unit_id_ != 1 )
		{
			msgTater->tater = this->unit_id_;
			msgTater->cb_count = this->callback_count_;
			msgTater->fr_count = this->frame_count_;
			msgTater->inFrame = this->inFrame_;
			for( unsigned int i=0; i < this->payload_size; i++ ) {
				msgTater->payload.push_back(i);
			}
			msgTater->publish(this->currFrame_, this->send_count_++);
		}

		// my processing is complete for this frame!
		this->sendEndFrame ();

		return 1;
}


int FramedTater::MonteCarlo_Step (Samson_Peer::MessageBase *)
{
		// if I am the first tater...pass it
		if(this->unit_id_==1)
		{
			msgTater->tater = this->unit_id_;
			msgTater->cb_count = this->callback_count_;
			msgTater->fr_count = this->frame_count_;
			msgTater->inFrame = this->inFrame_;
			for( unsigned int i=0; i < this->payload_size; i++ ) {
				msgTater->payload.push_back(i);
			}
			msgTater->publish(this->currFrame_, this->send_count_++);
		}

		// This will prevent an end of frame from being sent
		return 0;
}


int FramedTater::init(int argc, ACE_TCHAR *argv[])
{
		this->timer_.start ();

		ACE_Get_Opt get_opt (argc, argv, ACE_TEXT ("n:M:P:"));

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
			}
		}
		ACE_DEBUG ((LM_DEBUG, "FramedTater::init() %d of %d with %d passes\n", this->unit_id_,  this->max_taters_, this->max_passes_ ));

		int subscribeTo = (this->unit_id_ != 1)? this->unit_id_-1 : this->max_taters_;


		msgTater = auto_ptr<FramedTaterMsg>(new FramedTaterMsg(payload_size));
		MessageFunctor<FramedTater> passTheTaterFunctor(this,&FramedTater::passTheTater);
		msgTater->subscribe(&passTheTaterFunctor,subscribeTo);

		this->callback_count_=0;

		// this means I will get the "Step" message
		this->timing_.set(10);  // 10Hz

		return this->SamsonModel::init(argc,argv);
}

int FramedTater::fini(void)
{
		ACE_DEBUG((LM_DEBUG, "FramedTater::fini() %d called %d\n", this->unit_id_, this->callback_count_));

		this->timer_.stop ();
		ACE_Time_Value measured;
		this->timer_.elapsed_time (measured);
		double interval_sec = measured.msec () / 1000.0;
		ACE_DEBUG((LM_DEBUG,"Execution time %f\n", interval_sec));

		return 1;
}

ACE_FACTORY_DECLARE(ISE,FramedTater)

