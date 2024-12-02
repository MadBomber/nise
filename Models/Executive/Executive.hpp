#ifndef _EXECUTIVE_HPP
#define _EXECUTIVE_HPP

#include "ISE.h"
#include "SamsonModel.h"

namespace Samson_Peer { class MessageBase; }

class ISE_Export Executive : public Samson_Peer::SamsonModel
{
	public:
		Executive(): SamsonModel() {}
		~Executive() {}

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { if ( this->save_state_ ) toDB("Executive"); return 0; }
		virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) { return 0; }
		virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *) { return 1; }
		virtual int endSimulation(Samson_Peer::MessageBase *) { return 1; }

		// Engagement between Missile and Target is complete
		int RecEngagement(Samson_Peer::MessageBase *mb);


	private:

		#define ITEMS \
        ITEM(int,     tgtmsl_count) \
        ITEM(int,     num_reps_) // Number of "Monte Carlo Cases" to run; Read from the command line
        #include "model_states.inc"
};

ACE_FACTORY_DEFINE(ISE,Executive)

#endif

