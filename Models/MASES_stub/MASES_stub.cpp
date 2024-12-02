#define ISE_BUILD_DLL

#include "ISERelease.h"
#include "ISETrace.h" // first to toggle tracing

#include "MASES_stub.h"
#include "Model_ObjMgr.h"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "mysql.h"

int MASES_stub::init(int argc, ACE_TCHAR *argv[])
{
	BaseMsgObj = new ObjMessageTempl<CBaseMsg> (BaseMsg);
	LoadInputMsg = new ObjMessageTempl<CTraj3DOFMsg_LoadInput> (LoadInput);
	RemoteSetupMsg = new ObjMessageTempl<CTraj3DOFMsg_RemoteSetup> (RemoteSetup);
	TimeGrantMsg = new ObjMessageTempl<CTraj3DOFMsg_TimeGrant> (TimeGrant);

	TargetStatesMsg = new ObjMessageTempl<CTraj3DOFMsg_TargetStates> (TargetStates);
	MessageFunctor<MASES_stub>tsfunctor(this,&MASES_stub::processTargetStates);
	TargetStatesMsg->subscribe(&tsfunctor,0);

	ReplyMsgObj = new ObjMessageTempl<CISEReplyMsg> (ReplyMsg);
	MessageFunctor<MASES_stub>effunctor(this,&MASES_stub::processEndFrame);
	ReplyMsgObj->subscribe(&effunctor,0);


	// process the command line
	ACE_UNUSED_ARG(argc);
	ACE_UNUSED_ARG(argv);

	// used by MASES to make sure that it processes all messages
	this->msg_counter = 0;

	this->timing_.set(1);  // Hz

	return this->SamsonModel::init(argc,argv);
}


int MASES_stub::fini(void)
{
	delete LoadInputMsg;
	delete RemoteSetupMsg;
	delete TimeGrantMsg;
	delete TargetStatesMsg;
	return 1;
}


int  MASES_stub::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	// Find out how many TrajDOFs there are running
	count_Traj3DOF_  = Samson_Peer::SAMSON_OBJMGR::instance()->countAppKey("Traj3DOF");
	if ( count_Traj3DOF_ == 0 )
	{
		ACE_DEBUG ((LM_DEBUG, " MASES_stub::MonteCarlo_InitCase -> count(%d)  Stopping!\n", count_Traj3DOF_));
		return 0;
	}

	ACE_DEBUG ((LM_DEBUG, " MASES_stub::MonteCarlo_InitCase -> count(%d)\n", count_Traj3DOF_));


	// Publish two messages...
	LoadInput.m_iMsgID = this->msg_counter++;
	LoadInput.m_sMsgType = SM_LoadInput;
	for (int i=1; i<=count_Traj3DOF_; i++) {
		char sql[1024];
		sprintf(sql,"Select InputFile from MASES_Stub where PeerKey ='%s' and UnitID=%d;","Traj3DOF",i);

		MYSQL_RES  *result = Samson_Peer::SAMSON_OBJMGR::instance()->doQuery (sql, false);
		if ( result != NULL )
		{
			MYSQL_ROW row = mysql_fetch_row(result);
			if ( row)
			{
				LoadInput.m_csFile = row[0];
				LoadInputMsg->publish(this->currFrame_, this->send_count_++,i);
			}
			else
			{
				ACE_DEBUG ((LM_DEBUG, "MASES_stub::MonteCarlo_InitCase:  No Input File found (%s)\n",sql));
				return 0;
			}
		}
		else
		{
			ACE_DEBUG ((LM_DEBUG, "MASES_stub::MonteCarlo_InitCase error: (%s)\n",sql));
			return 0;
		}
		Samson_Peer::SAMSON_OBJMGR::instance()->freeQuery (result);
	}

	RemoteSetup.m_iMsgID = this->msg_counter++;
	RemoteSetup.m_sMsgType = SM_RemoteSetup;
	RemoteSetup.m_iMissileID = 1;
	RemoteSetup.m_iUnits = 2;  // from example;
	RemoteSetup.m_iFrame = 3;  // from example;
	RemoteSetup.m_dTime0 = 0.0;
	RemoteSetup.m_dTimeFinal=100.0;  // from example;
	RemoteSetup.m_iOpt=0;
	RemoteSetup.m_dPosLaunch[0] = 0.0;
	RemoteSetup.m_dPosLaunch[1] = 0.0;
	RemoteSetup.m_dPosLaunch[2] = 0.0;
	RemoteSetup.m_dPosImpact[0] = 0.0;
	RemoteSetup.m_dPosImpact[1] = 0.0;
	RemoteSetup.m_dPosImpact[2] = 0.0;
	RemoteSetup.m_dRange = 10150.0;  // from example;
	RemoteSetup.m_dHeading = 0.0;  // from example;
	RemoteSetup.m_bLoft = 0;
	for (int i=1; i<=count_Traj3DOF_; i++) RemoteSetupMsg->publish(this->currFrame_, this->send_count_++,i);

	BaseMsg.m_iMsgID = this->msg_counter++;
	BaseMsg.m_sMsgType = SM_Initialization;
	for (int i=1; i<=count_Traj3DOF_; i++) BaseMsgObj->publish(this->currFrame_, this->send_count_++, i);

	BaseMsg.m_iMsgID = this->msg_counter++;
	BaseMsg.m_sMsgType = SM_Execute;
	for (int i=1; i<=count_Traj3DOF_; i++) BaseMsgObj->publish(this->currFrame_, this->send_count_++, i);

	return 1;
}

int  MASES_stub::MonteCarlo_Step(Samson_Peer::MessageBase *)
{
	toDB("MASES_stub");
	TimeGrant.m_iMsgID = this->msg_counter++;
	TimeGrant.m_sMsgType = SM_TimeGrant;
	TimeGrant.m_dTimeGrant = this->currTime_;
	for (int i=1; i<=count_Traj3DOF_; i++) TimeGrantMsg->publish(this->currFrame_, this->send_count_++, i);

	// ...then stop
	if (this->currTime_ > 80.0 )
	{
		this->sendEndCase();

		BaseMsg.m_iMsgID = this->msg_counter++;
		BaseMsg.m_sMsgType = SM_Terminate;
		for (int i=1; i<=count_Traj3DOF_; i++) BaseMsgObj->publish(this->currFrame_, this->send_count_++, i);
	}

	return 0;
}


int MASES_stub::processTargetStates(Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	ACE_DEBUG ((LM_DEBUG, " MASES_stub::processTargetState(%d:%d(%d):%d:%d) at %f : ",
                                sh->run_id(),
                                sh->message_id(),
                                sh->app_msg_id(),
                                sh->peer_id(),
                                sh->unit_id(),
                                this->currTime_));

	ACE_DEBUG ((LM_DEBUG, "%f ",TargetStates.m_dTime));
	for (int i=0;i<9;i++) ACE_DEBUG ((LM_DEBUG, "%f ",TargetStates.m_dStates[i]));
	ACE_DEBUG ((LM_DEBUG, "\n"));

	return 1;
}

int MASES_stub::processEndFrame(Samson_Peer::MessageBase *mb)
{
	static int frame_count = 0;
	const SamsonHeader *sh = mb->get_header();

	ACE_DEBUG ((LM_DEBUG, " MASES_stub::processEndFrame(%d:%d(%d):%d:%d) at %f \n",
                                sh->run_id(),
                                sh->message_id(),
                                sh->app_msg_id(),
                                sh->peer_id(),
                                sh->unit_id(),
                                this->currTime_));

	if ( ReplyMsg.m_sMsgType == SM_EndFrame )
		if (  ++frame_count == count_Traj3DOF_ )
		{
			this->sendEndFrame ();
			frame_count = 0;
		}

	return 1;
}

ACE_FACTORY_DECLARE(ISE,MASES_stub)

///......................................................................................
// the class factories for a dynamic loaded library

extern "C" ISE_Export MASES_stub* create() {
	MASES_stub *ptr = 0;
	ACE_NEW_RETURN (ptr, MASES_stub, 0);
	return ptr;
}

extern "C" ISE_Export void destroy(MASES_stub* p) {
        delete p;
}

