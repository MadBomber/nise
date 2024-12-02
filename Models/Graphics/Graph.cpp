////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Graph.cpp
//
// Classification:   UNCLASSIFIED
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

#include "ISE.h"

#include "Graph.h"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "MessageFunctor.hpp"
#include "Model_ObjMgr.h"

#include <cmath>
#include <sstream>
#include <string>

//#include <stdio.h>
//#include <unistd.h>
//#include <stdlib.h>
//#include <sys/time.h>

/* Exec the named cmd as a child process, returning
 * two pipes to communicate with the process, and
 * the child's process ID */
int start_child( const char * const cmd, FILE **readpipe, FILE **writepipe)
{
	int childpid, pipe1[2], pipe2[2];
	if ((pipe(pipe1) < 0) || (pipe(pipe2) < 0))
	{
		perror("pipe");
		exit(-1);
	}
	if ((childpid = vfork()) < 0)
	{
		perror("fork");
		exit(-1);
	}
	else if (childpid > 0)
	{ /* Parent. */
		close(pipe1[0]);
		close(pipe2[1]);
		/* Write to child is pipe1[1], read from
		 * child is pipe2[0].  */
		*readpipe = fdopen(pipe2[0], "r");
		*writepipe=fdopen(pipe1[1], "w");
		setlinebuf(*writepipe);
		return childpid;
	}
	else
	{ /* Child. */
		close(pipe1[1]);
		close(pipe2[0]);
		/* Read from parent is pipe1[0], write to
		 * parent is pipe2[1].  */
		dup2(pipe1[0], 0);
		dup2(pipe2[1], 1);
		close(pipe1[0]);
		close(pipe2[1]);
		if (execlp(cmd, cmd, NULL) < 0)
			perror("execlp");
		/* Never returns */
	}
	return 0;
}

int Graphic::init(int argc, ACE_TCHAR *argv[])
{
	// setup the messages
	//this->mDownlink = new ObjMessageTempl<MyMissileDownlink> (aDownlink); // receive
	this->mDownlink = new MyMissileDownlink(); // receive
	this->mTgtTruth = new TruthTargetStates(); // receive
	MessageFunctor<Graphic> srfunctor(this, &Graphic::processTargetInput);
	mDownlink->subscribe(&srfunctor, 0);
	mTgtTruth->subscribe(&srfunctor, 0);

	start_child("gnuplot", &read_from, &write_to);
	//fprintf(write_to,"plot [-3:3] sin(x)/x\n");
	//printf("plot [0:1500] [25000:50000] '-' title \"Target 1\" with lines\n0 25000\n1000 45000\ne\n");
	fprintf(write_to,
			"plot [0:50] [0:6000] '-' title \"Target 1\" with lines\n0 0\n10 0\ne\n");

	start_child("gnuplot", &read_from2, &write_to2);
	fprintf(write_to2,
			"plot [0:50] [0:6000] '-' title \"Target 2\" with lines\n0 0\n10 0\ne\n");

	this->timing_.set(10); // 10Hz
	return this->SamsonModel::init(argc, argv);
}

//March, 1998 pg. 90; corrected April, 1998 pg. 94
template<class T> std::string toString(const T &a)
{
	std::ostringstream Stream;
	Stream<<a;
	return Stream.str();
}

int Graphic::fini(void)
{
	delete mTgtTruth;
	return 1;
}

int Graphic::processTargetInput(Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	//mTgtTruth->print();
	int unitID = sh->unit_id();
	int modelID = sh->peer_id();
	char name[85];
	Samson_Peer::SAMSON_OBJMGR::instance()->getModelKey(modelID, name);
	position = mTgtTruth->position_;
	static std::string plot1("replot\n"), plot2("replot\n");
	if (!strcmp(name, "Target"))
	{
		FILE *w=(unitID==1) ? write_to : write_to2;
		std::string& plot=(unitID==1) ? plot1 : plot2;
		static int xaxis=0;
		//if(!(xaxis & 0x000f)) {
		//    double x=position.getX();
		//    double y=position.getY();
		double z=position.getZ();
		//plot+=toString(this->currTime_)+' '+toString(sqrt(x*x+y*y+z*z))+'\n';
		plot+=toString(this->currTime_)+' '+toString(z)+'\n';
		fprintf(w, plot.c_str());
		fprintf(w, "e\n");
		//}
		++xaxis;
	}

	return 1;
}

ACE_FACTORY_DECLARE(ISE,Graphic)
