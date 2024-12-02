#define ISE_BUILD_DLL

// local includes
#include "DIS.h"
#include "pdu_packed.h"
#include "Coord.h"

#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "Model_ObjMgr.h"
#include "mysql.h"
#include <string>
#include <fstream>

#include <boost/regex.hpp>
#include <boost/tuple/tuple.hpp>

#include "Simplej_SpaceTrack.h"

using namespace dis;
using namespace boost::tuples;

static int dgram_port  = 3000;

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
	es.header.exercise_id =12;
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
	es.entity_type.domain =2; //=2;
	es.entity_type.country =225;//=225;
	es.entity_type.category =1; //=1;
	es.entity_type.subcategory =6; //=3;
	es.entity_type.specific =1; //=3;
	es.entity_type.extra =1; //=0;
	es.alt_entity_type = es.entity_type;
	return es;
}

//..............................................................................................
int scale(double val, double factor, int neg_offset)
{
	int ival = val*factor;
	if (val<0.0) ival += neg_offset;
	return ival;
}

} // namespace


//.................................................................................
DIS::DIS() : SamsonModel(),
             MissileToTrkRadarOutput(new MyMissileDownlink()),
             mTargetState(new TruthTargetStates()),
             mLLA_Vehicle_State(new LLA_Vehicle_State())
{
}

//.................................................................................
int DIS::init(int argc, ACE_TCHAR *argv[])
{
	ACE_UNUSED_ARG(argc);
	ACE_UNUSED_ARG(argv);

#define SUBSCRIBE(VAR) \
  VAR = new typeof(*VAR); \
  VAR->subscribe(makeCallback(VAR),0);

	MessageFunctor<DIS> targetoutput(this, &DIS::processTarget);
	mTargetState ->subscribe(&targetoutput, 0);

	MessageFunctor<DIS> missileoutput(this, &DIS::processMissile);
	MissileToTrkRadarOutput ->subscribe(&missileoutput, 0);

	MessageFunctor<DIS> lla_output(this, &DIS::processLLA);
	mLLA_Vehicle_State ->subscribe(&lla_output, 0);

#undef SUBSCRIBE

	// open up the UDP broadcast

    if (this->dis_socket.open (ACE_Addr::sap_any) == -1)
    {
    	ACE_DEBUG((LM_ERROR, "(%P|%t) DIS::init: UDP Broadcast Socket error"));
    	return -1;
    }

	this->timing_.set(10); // 10Hz
	return this->SamsonModel::init(argc, argv);
}


//.................................................................................
int DIS::fini(void)
{
	this->dis_socket.close ();
	return 1;
}



//.................................................................................
int DIS::processTarget(Samson_Peer::MessageBase *mb)
{
	//static int count = 0;
	double N =mTargetState->position_.getX();
	double E =mTargetState->position_.getY();
	double D =mTargetState->position_.getZ();
	double R =mTargetState->attitude_.getX();
	double P =mTargetState->attitude_.getY();
	double Y =mTargetState->attitude_.getZ();

	//return (count++%20 == 0) ? processToDIS(mb, N, E, D, Y, P, R, false): 1 ;
	return processToDIS(mb, N, E, D, Y, P, R, false);
}

//.................................................................................
int DIS::processMissile(Samson_Peer::MessageBase *mb)
{
	double N =MissileToTrkRadarOutput->position_.getX();
	double E =MissileToTrkRadarOutput->position_.getY();
	double D =MissileToTrkRadarOutput->position_.getZ();
	double R =MissileToTrkRadarOutput->attitude_.getX();
	double P =MissileToTrkRadarOutput->attitude_.getY();
	double Y =MissileToTrkRadarOutput->attitude_.getZ();
	return processToDIS(mb, N, E, D, Y, P, R, true);
	//return 1;
}

//.................................................................................
int DIS::processLLA(Samson_Peer::MessageBase *mb)
{
	double t     = mLLA_Vehicle_State->time_;

#if 0
	const SamsonHeader *sh = mb->get_header();
	int unitID = sh->unit_id();

	ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processLLA: (LLA V YPR) %d %f %f %f %f %f %f %f %f %f %f\n",
						unitID,
						t,
    		    		mLLA_Vehicle_State->lla_.getX(),
    		    		mLLA_Vehicle_State->lla_.getY(),
    		    		mLLA_Vehicle_State->lla_.getZ(),
    		    		mLLA_Vehicle_State->velocity_.getX(),
    		    		mLLA_Vehicle_State->velocity_.getY(),
    		    		mLLA_Vehicle_State->velocity_.getZ(),
    		    		mLLA_Vehicle_State->attitude_.getZ(),
    		    		mLLA_Vehicle_State->attitude_.getY(),
    		    		mLLA_Vehicle_State->attitude_.getX()
    ));
#endif

    Degrees lat(mLLA_Vehicle_State->lla_.getX());
	Degrees lon(mLLA_Vehicle_State->lla_.getY());
	Degrees alt(mLLA_Vehicle_State->lla_.getZ());
	double x,y,z;
	tie(x,y,z) = coord::lat_lon_alt_to_gcc(lat,lon,alt);

	double vx,vy,vz;
	double vvx    = mLLA_Vehicle_State->velocity_.getX();
	double vvy    = mLLA_Vehicle_State->velocity_.getY();
	double vvz    = mLLA_Vehicle_State->velocity_.getZ();
	tie(vx,vy,vz) = lcs.to_gcc_delta(vvy,vvx,-vvz);
	vx = vy = vz = 0.0;

	// Assumption:  ypr are in Degrees !!!!
	Degrees Y(mLLA_Vehicle_State->attitude_.getZ());
	Degrees P(mLLA_Vehicle_State->attitude_.getY());
	Degrees R(mLLA_Vehicle_State->attitude_.getX());
	double psi, theta, phi;
	tie(psi, theta, phi) = coord::lat_lon_hpr_to_psi_theta_phi(lat, lon, Y, P, R);

#if 0
    ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processLLA: (LLA V YPR) %f %f %f %f %f %f %f %f %f\n",
    		x, y, z, vx, vy, vz, psi, theta, phi
    ));
#endif

	toDIS(mb, t, x, y, z, vx, vy, vz, psi, theta, phi, false);
	return 1;
}

//.................................................................................
int DIS::processToDIS(Samson_Peer::MessageBase *mb, double N, double E,
		double D, double Y, double P, double R, bool friendly)
{

	ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI: (NEDYPR) %f %f %f %f %f %f\n", N, E, D, Y, P, R));

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
	tie(x, y, z)=lcs.to_gcc(N, E, D);
	es.location[0] = x;
	es.location[1] = y;
	es.location[2] = z;

	double alt = sqrt(x*x+y*y+z*z) - 6.371e+6;

	ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI(location): %f %f %f  -> %g %g %g (%g)\n", N, E, D, x, y, z, alt ));

	//float psi, theta, phi;
	double psi, theta, phi;
	tie(psi, theta, phi) = coord::lat_lon_hpr_to_psi_theta_phi(lat_origin, lon_origin, Degrees(Y), Degrees(P), Degrees(R));

	//ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI(attitude): %f %f %f  -> %f %f %f\n", Y, P, R, psi, theta, phi));

	es.orientation[0] = psi;
	es.orientation[1] = theta;
	es.orientation[2] = phi;

	es.dead_reckoning_algorithm = 1; //2;
	es.character_set = 1; //ASCII
	for (int i=0; i<=10; ++i)
		es.entity_marking[i]="Target\0\0\0\0"[i];
	es.capabilities =0;

/*
    if (this->dis_socket.send (es.begin(), es.size(), dgram_port) < 0 )
	{
        ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT ("%p\n"),
                           ACE_TEXT ("Cannot broadcast datagram")), 1);   // TODO: need real error return!
	}
*/

	ACE_INET_Addr bad_practice(dgram_port, "138.209.52.6"); // FIXME: parameterize the IP
	if (this->dis_socket.send (es.begin(), es.size(), bad_practice) < 0 )
	{
		ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT ("%p\n"),
				ACE_TEXT ("Cannot broadcast datagram")), 1);   // TODO: need real error return!
	}
	else
        ACE_DEBUG ((LM_INFO, ACE_TEXT ("DIS Packet sent\n")));
	return 1;
}

//.................................................................................
int DIS::toDIS(Samson_Peer::MessageBase *mb,    double t,
                      double x,   double y,     double z,
                      float  vx,  float  vy,    float  vz,
                      float  psi, float  theta, float phi,
                      bool friendly)
{
	static unsigned int counter = 0;

	//ACE_DEBUG((LM_DEBUG, "(%P|%t) DIS::processToDI: (NEDYPR) %f %f %f %f %f %f\n", N, E, D, Y, P, R));

	static EntityStatePDU es=initEntityStatePDU();
	es.force_id = friendly ? 1 : 2;

	const SamsonHeader *sh = mb->get_header();
	int unitID = sh->unit_id();
	int modelID = sh->peer_id();

	// Note: using this->modelID as the entity
	es.entity_id.entity = unitID<<8|modelID;

	es.velocity[0] = vx;
	es.velocity[1] = vy;
	es.velocity[2] = vz;

	es.location[0] = x;
	es.location[1] = y;
	es.location[2] = z;

	es.orientation[0] = psi;
	es.orientation[1] = theta;
	es.orientation[2] = phi;

	es.dead_reckoning_algorithm = 1; //2;
	es.character_set = 1; //ASCII
	for (int i=0; i<=10; ++i)
		es.entity_marking[i]="Target\0\0\0\0"[i];
	es.capabilities =0;

/*
    if (this->dis_socket.send (es.begin(), es.size(), dgram_port) < 0 )
    {
        ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT ("%p\n"),
                           ACE_TEXT ("Cannot broadcast datagram")), 1);   // TODO: need real error return!
    }
*/
	ACE_INET_Addr bad_practice(dgram_port, "138.209.52.6"); // FIXME: parameterize the IP
	if (this->dis_socket.send (es.begin(), es.size(), bad_practice) < 0 )
		ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT ("%p\n"),
				ACE_TEXT ("Cannot broadcast datagram")), 1);   // TODO: need real error return!
#if 1
    else
        ACE_DEBUG ((LM_INFO, ACE_TEXT ("DIS Packet sent %d\n"),counter++));
#endif

#if 1
		// ---------
		// Link16 area
		// - create the message component
		// - allocate a place to pack it all up
		// - compute the data
		// - pack and send to a CID (Connection ID)

		SimpleJ_Header  hdr1;
		SimpleJ_Link16_Type_Header hdr11;
		Link16_Common l16_common;
		Link16_SpaceTrack st;
		SimpleJ_Footer  footer;

		int pkt_size = ((hdr1.bits() + hdr11.bits() + l16_common.bits() + st.bits() + footer.bits()) +7) >> 3;
		Vec vpk(pkt_size);
		Pack pk(vpk);

		/*
		ACE_DEBUG((LM_INFO,"RamThreat::MonteCarlo_Step -> SimpleJ size=%d %d %d %d %d %d \n",
				hdr1.bits(),hdr11.bits(),l16_common.bits(),st.bits(),footer.bits(),
				pkt_size
			));
		*/

		st.Minute = 0;
		st.Second = int(t);
		//st.Second = int((t-int(t))*100);

		// RM### where ### is the unit id
		st.TN_LS_3_bit = unitID & 7;
		st.TN_Mid_3_bit = unitID >> 3 & 7;
		st.TN_MS_3_bit = unitID >> 6 & 7;
		st.TN_MS_5_bit = 027; // R
		st.TN_LS_5_bit = 023; // M

		// compute the data
		st.X_Position = scale(x,0.1,0x800000);
		st.Y_Position = scale(y,0.1,0x800000);
		st.Z_Position = scale(z,0.1,0x800000);

		st.X_Velocity = scale(vx,1.0/3.33,0x2000);
		st.Y_Velocity = scale(vy,1.0/3.33,0x2000);
		st.Z_Velocity = scale(vz,1.0/3.33,0x2000);

		// pack the link16 message

		hdr1.for_each(pk);
		hdr11.for_each(pk);
		l16_common.for_each(pk);
		st.for_each(pk);
		pk.add_checksum();

		char *silly = reinterpret_cast<char *>(&vpk[0]);
		this->sendMsgOnCID (4, silly, vpk.size());

		// End Link16
		// ---------

#endif





	return 1;
}

ACE_FACTORY_DECLARE(ISE,DIS)
