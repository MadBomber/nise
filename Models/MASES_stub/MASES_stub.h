#ifndef _MASES_STUB_H_
#define _MASES_STUB_H_

#include "ace/ACE.h"
#include "ISEExport.h"
#include "SamsonModel.h"
#include "ObjMessage.h"

#include "Traj3DOF_Msg.h"

namespace Samson_Peer { class MessageBase; }

class ISE_Export MASES_stub : public Samson_Peer::SamsonModel
{
	public:

		CBaseMsg  BaseMsg;
		CISEReplyMsg ReplyMsg;
		CTraj3DOFMsg_LoadInput  LoadInput;
		CTraj3DOFMsg_RemoteSetup RemoteSetup;
		CTraj3DOFMsg_TimeGrant TimeGrant;
		CTraj3DOFMsg_TargetStates TargetStates;

		ObjMessageTempl<CBaseMsg> *BaseMsgObj;
		ObjMessageTempl<CISEReplyMsg> *ReplyMsgObj;
		ObjMessageTempl<CTraj3DOFMsg_LoadInput> *LoadInputMsg;
		ObjMessageTempl<CTraj3DOFMsg_RemoteSetup> *RemoteSetupMsg;
		ObjMessageTempl<CTraj3DOFMsg_TimeGrant> *TimeGrantMsg;
		ObjMessageTempl<CTraj3DOFMsg_TargetStates> *TargetStatesMsg;

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		int processTargetStates (Samson_Peer::MessageBase *mb);
		int processEndFrame (Samson_Peer::MessageBase *mb);


		// base class needs 1 to continue
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) { return 1; }

	protected:

		#define ITEMS \
		ITEM(int,    msg_counter) \
		ITEM(int,    count_Traj3DOF_)
		#include "model_states.inc"
};

ACE_FACTORY_DEFINE(ISE,MASES_stub)

#endif
