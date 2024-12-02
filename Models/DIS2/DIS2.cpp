#define ISE_BUILD_DLL

// local includes
#include "DIS2.h"
#include "pdu_packed.h"
#include "Coord.h"


#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "Model_ObjMgr.h"
#include "mysql.h"
#include <string>
#include <fstream>

#include <boost/regex.hpp>

using namespace dis;
using namespace boost::tuples;

static int exercise_id = 20;
static int dgram_port  = 3020;

namespace
{

//const Degrees lat_origin(  35.94722); //hunter-liggett
//const Degrees lon_origin(-121.17361);

const Degrees lat_origin( 27.16861); //bandar
const Degrees lon_origin( 56.17484);

coord::LCS lcs(lat_origin, lon_origin);

/*
const std::string BROADCAST_ADDRESS=broadcast_address("eth0");
INET_Address bcast(BROADCAST_ADDRESS, 3020);
UDP_socket radio(3020);
*/

EntityStatePDU initEntityStatePDU()
{
	EntityStatePDU es;

	//int es_size=0;
	//es.for_each(Count(es_size));

	es.header.protocol_version =4;
	es.header.exercise_id =exercise_id;
	es.header.pdu_type =1;
	es.header.protocol_family =1; //Config.Protocol_family;
	es.header.time_stamp =1234;
	es.header.length =es.size();
	es.header.padding =0;
	es.entity_id.site =61;
	es.entity_id.application =39;
	es.entity_id.entity =1005;
	es.force_id =1;
	es.num_articulation_params =0;
	es.entity_type.kind =2; //=1;
	es.entity_type.domain =1; //=2;
	es.entity_type.country =255;//=225;
	es.entity_type.category =1; //=1;
	es.entity_type.subcategory =6; //=3;
	es.entity_type.specific =1; //=3;
	es.entity_type.extra =1; //=0;
	es.alt_entity_type = es.entity_type;
	return es;
}

} // namespace


//.................................................................................
int DIS2::init(int argc, ACE_TCHAR *argv[])
{
	ACE_UNUSED_ARG(argc);
	ACE_UNUSED_ARG(argv);

	// Only a Start of Frame !!!!!
	this->separate_advance_time_ = false;
 
	path_.push_back(WayPoint( 56.38713562943536,27.23195345932947,10,.16667 ));
	path_.push_back(WayPoint ( 56.37965389362012,27.21924894440819,50,.16667 ));
	path_.push_back(WayPoint ( 56.37113126376319,27.20477911580908,500,.16667  ));
	path_.push_back(WayPoint ( 56.40292779638973,27.16543775199442,1500,.16667  ));
	path_.push_back(WayPoint ( 56.68612814512881,26.73759747842227,5000,.16667  ));
	path_.push_back(WayPoint ( 57.41375057424977,25.74836125027824,10000,.16667  ));
	path_.push_back(WayPoint ( 58.19272562186809,25.03192293995436,10000,.16667  ));
	path_.push_back(WayPoint ( 57.70596663788606,24.68353392681291,10000,.16667  ));
	path_.push_back(WayPoint ( 56.66671006404006,25.45420037689536,10000,.16667  ));
	path_.push_back(WayPoint ( 56.44261895119726,26.60849079785284,10000,.16667  ));
	path_.push_back(WayPoint ( 53.75778272995753,25.17274005360037,10000,.16667  ));
	path_.push_back(WayPoint ( 53.72698475773784,26.08293536054368,10000,.16667  ));
	path_.push_back(WayPoint ( 54.93056643433106,26.01405473367423,10000,.16667  ));
	path_.push_back(WayPoint ( 55.32002455539371,26.36978546259198,10000,.16667  ));
	path_.push_back(WayPoint ( 55.85831951738142,26.55061361451593,5000,.16667  ));
	path_.push_back(WayPoint ( 56.37638304701274,27.25529998625124,1000,.16667  ));
	path_.push_back(WayPoint ( 56.39486033164841,27.25981463870624,500,.16667  ));
	path_.push_back(WayPoint ( 56.39343920597472,27.24280997934855,300,.16667  ));
	path_.push_back(WayPoint ( 56.38671356350633,27.23138527851264,10,.16667 ));
	
	double t = 0.0;
	for ( unsigned int i=0; i<path_.size(); i++)
	{
		if ( i > 0 ) 
		{
			path_[i-1].bearing(path_[i]);
			double d = path_[i-1].distance(path_[i]);
			double r = path_[i-1].grnd_spd();
			t += d / r;
			ACE_DEBUG((LM_INFO, "(%P|%t) DIS::init: T=%f\n",t));
		}
		path_[i].time(t);
	}

	for ( unsigned int i=0; i<path_.size(); i++)
	{
		path_[i].print();
	}
	
	// open up the UDP broadcast 
	
    if (this->dis_socket.open (ACE_Addr::sap_any) == -1) 
    {
    	ACE_ERROR_RETURN((LM_ERROR, "(%P|%t) DIS::init: UDP Broadcast Socket error"),-1);
    }
	
	this->timing_.set(10); // 10Hz
	return this->SamsonModel::init(argc, argv);
}


//.................................................................................
int DIS2::fini(void)
{
	this->dis_socket.close ();

	//  Print scheduling measurements
	this->schedule_stats_.print();

	return 1;
}



//.................................................................................
int DIS2::MonteCarlo_Step(Samson_Peer::MessageBase *mb)
{
	static int i = 0;
	static bool first_call = true;
	
	ACE_DEBUG ((LM_INFO, ACE_TEXT ("Step: T= %f\n"),this->currTime_));
	
	/*int retval = */ processToDIS(mb, path_[i], false);
	i = (i+1)%path_.size();
	
	// Collect timing
	if (!first_call)
	{
		ACE_hrtime_t measured;
		this->frame_timer_.stop ();
		this->frame_timer_.elapsed_microseconds (measured);
		this->schedule_stats_.sample (measured*1.0e-6);
	}
	else
		first_call = false;
	
	this->frame_timer_.start ();
	
	return 0;  // don't send an end of frame !!!!
}

//.................................................................................
int DIS2::processToDIS(Samson_Peer::MessageBase *mb, WayPoint &point, bool friendly)
{
	
	//ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI: (NEDYPR) %f %f %f %f %f %f\n", N, E, D, Y, P, R));

	static EntityStatePDU es=initEntityStatePDU();
	es.force_id = friendly ? 1 : 2;

	const SamsonHeader *sh = mb->get_header();
	int unitID = sh->unit_id();
	int modelID = sh->peer_id();

	// Note: using this->modelID as the entity
	es.entity_id.entity = unitID<<8|modelID;

	//  double vx, vy, vz; //, s=0;
	//  lcs.to_gcc_delta(N, E, -D, vx, vy, vz);

	es.velocity[0] = 0.0; //vx*s;
	es.velocity[1] = 0.0; //vy*s;
	es.velocity[2] = 0.0; //vz*s;

	double x, y, z;
	tie(x, y, z) = coord::lat_lon_alt_to_gcc( Radians(point.lat()), Radians(point.lon()), point.alt() );
	es.location[0] = x;
	es.location[1] = y;
	es.location[2] = z;

	double alt = sqrt(x*x+y*y+z*z) - 6.371e+6;
	
	ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI(location): %f %f %f  -> %g %g %g (%g)\n", double(point.lat()), double(point.lon()), point.alt(), x, y, z, alt ));
	
	//float psi, theta, phi;
	double psi, theta, phi;
	tie(psi, theta, phi) = coord::lat_lon_hpr_to_psi_theta_phi(lat_origin, lon_origin, Degrees(0.0), Degrees(0.0), Degrees(0.0));

	//ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI(attitude): %f %f %f  -> %f %f %f\n", Y, P, R, psi, theta, phi));

	es.orientation[0] = psi;
	es.orientation[1] = theta;
	es.orientation[2] = phi;

	es.dead_reckoning_algorithm = 1; //2;
	es.character_set = 1; //ASCII
	for (int i=0; i<=10; ++i)
		es.entity_marking[i]="Target\0\0\0\0"[i];
	es.capabilities =0;
	
    if (this->dis_socket.send (es.begin(), es.size(), dgram_port) < 0 )
        ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT ("%p\n"),
                           ACE_TEXT ("Cannot broadcast datagram")), 1);   // TODO: need real error return!
    else
        ACE_DEBUG ((LM_INFO, ACE_TEXT ("DIS Packet sent\n")));
	return 1;
}

ACE_FACTORY_DECLARE(ISE,DIS)
