#ifndef _CTraj3DOFMsg_H_
#define _CTraj3DOFMsg_H_

#include "BaseMsg.h"
#include "FrameTypes.h"

///////////////////////////////////////////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////// 
//			Message Set
///////////////////////////////////////////////////////////////////////////// 
//	CBaseMsg
//	CTraj3DOFMsg_LoadInput
//	CTraj3DOFMsg_RemoteSetup
//	CTraj3DOFMsg_TimeGrant
//	CTraj3DOFMsg_TargetStates
///////////////////////////////////////////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////// 

///////////////////////////////////////////////////////////////////////////// 
//
///////////////////////////////////////////////////////////////////////////// 
class CTraj3DOFMsg_LoadInput : public CBaseMsg
{ 
public:
	CTraj3DOFMsg_LoadInput(); 
	CTraj3DOFMsg_LoadInput(const CTraj3DOFMsg_LoadInput& msg); 

	// Attributes 
	std::string m_csFile;

	// Operations 
	CTraj3DOFMsg_LoadInput& operator=(const CTraj3DOFMsg_LoadInput& msg);	// assignment
	void Copy(const CTraj3DOFMsg_LoadInput& msg);

	// Implementation
	virtual ~CTraj3DOFMsg_LoadInput();

protected:
	friend class boost::serialization::access;
	template<class Archive>
	void serialize(Archive &ar, const unsigned int) 
	{
		ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(CBaseMsg);
		ar & BOOST_SERIALIZATION_NVP(m_csFile);
	}
}; 

///////////////////////////////////////////////////////////////////////////// 
//
///////////////////////////////////////////////////////////////////////////// 
class CTraj3DOFMsg_RemoteSetup : public CBaseMsg
{ 
public:
	CTraj3DOFMsg_RemoteSetup(); 
	CTraj3DOFMsg_RemoteSetup(const CTraj3DOFMsg_RemoteSetup& msg); 

	// Attributes 
	int		m_iMissileID;			// Missile ID
	int		m_iUnits;				// Units 1=English, 2=Metric
	int		m_iFrame;				// Desire frame of output data
									//	0 = ECI		Earth Centered Inertial
									//	1 = ECEF	Earth Centered Earth Fixed
									//				(X-Long 90, Y-Long 180, Z-North Pole)
									//	2 = ENU		East, North, Up
									//	3 = NED		North, East, Down
									//	4 = NWU		North, West, Up
									//	5 = WUN		West, Up, North
									//	6 = LLA		Latitude, Longitude, Altitude (Geocentric)
									//	7 = LLA_GD	Latitude, Longitude, Altitude (Geodetic)
	double	m_dTime0;				// Initial Time													sec
	double	m_dTimeFinal;			// Final Time													sec

	int		m_iOpt;					// 0 = Initialize based on namelist inputs
									// 1 = Initialize based on launch point
									// 2 = Initialize based on launch & impact points
									// 3 = Initialize based on launch & range & heading
	double	m_dPosLaunch[3];		// Launch position in ECEF	
	double	m_dPosImpact[3];		// Impact position in ECEF	
	double	m_dRange;				// Surface range to predicted impact point 						ft,m
	double	m_dHeading;				// Initial heading												deg
	bool	m_bLoft;				// 0 = Depressed Trajectory
									// 1 = Lofted Trajectory

	// Operations 
	CTraj3DOFMsg_RemoteSetup& operator=(const CTraj3DOFMsg_RemoteSetup& msg);	// assignment
	void Copy(const CTraj3DOFMsg_RemoteSetup& msg);

	// Implementation
	virtual ~CTraj3DOFMsg_RemoteSetup();

protected:
	friend class boost::serialization::access;
	template<class Archive>
	void serialize(Archive &ar, const unsigned int) 
	{
		ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(CBaseMsg);
		ar & BOOST_SERIALIZATION_NVP(m_iMissileID);
		ar & BOOST_SERIALIZATION_NVP(m_iUnits);
		ar & BOOST_SERIALIZATION_NVP(m_iFrame);
		ar & BOOST_SERIALIZATION_NVP(m_dTime0);
		ar & BOOST_SERIALIZATION_NVP(m_dTimeFinal);
		ar & BOOST_SERIALIZATION_NVP(m_iOpt);
		ar & BOOST_SERIALIZATION_NVP(m_dPosLaunch);
		ar & BOOST_SERIALIZATION_NVP(m_dPosImpact);
		ar & BOOST_SERIALIZATION_NVP(m_dRange);
		ar & BOOST_SERIALIZATION_NVP(m_dHeading);
		ar & BOOST_SERIALIZATION_NVP(m_bLoft);
	}
}; 

///////////////////////////////////////////////////////////////////////////// 
//
///////////////////////////////////////////////////////////////////////////// 
class CTraj3DOFMsg_TimeGrant : public CBaseMsg
{ 
public:
	CTraj3DOFMsg_TimeGrant(); 
	CTraj3DOFMsg_TimeGrant(const CTraj3DOFMsg_TimeGrant& msg); 

	// Attributes 
	double			m_dTimeGrant;

	// Operations 
	CTraj3DOFMsg_TimeGrant& operator=(const CTraj3DOFMsg_TimeGrant& msg);	// assignment
	void Copy(const CTraj3DOFMsg_TimeGrant& msg);

	// Implementation
	virtual ~CTraj3DOFMsg_TimeGrant();

protected:
	friend class boost::serialization::access;
	template<class Archive>
	void serialize(Archive &ar, const unsigned int) 
	{
		ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(CBaseMsg);
		ar & BOOST_SERIALIZATION_NVP(m_dTimeGrant);
	}
}; 

///////////////////////////////////////////////////////////////////////////// 
//
///////////////////////////////////////////////////////////////////////////// 
class CTraj3DOFMsg_TargetStates : public CBaseMsg
{ 
public:
	CTraj3DOFMsg_TargetStates(); 
	CTraj3DOFMsg_TargetStates(const CTraj3DOFMsg_TargetStates& msg); 

	// Attributes 
	SFrameType		m_SFrame;
	SUnitType		m_SUnits;
	double			m_dTime;
	double			m_dStates[9];		// Pos[3],Vel[3],Acc[3]

	// Operations 
	CTraj3DOFMsg_TargetStates& operator=(const CTraj3DOFMsg_TargetStates& msg);	// assignment
	void Copy(const CTraj3DOFMsg_TargetStates& msg);

	// Implementation
	virtual ~CTraj3DOFMsg_TargetStates();

protected:
	friend class boost::serialization::access;
	template<class Archive>
	void serialize(Archive &ar, const unsigned int) 
	{
		ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(CBaseMsg);
		ar & BOOST_SERIALIZATION_NVP(m_SFrame);
		ar & BOOST_SERIALIZATION_NVP(m_SUnits);
		ar & BOOST_SERIALIZATION_NVP(m_dTime);
		ar & BOOST_SERIALIZATION_NVP(m_dStates);
	}
}; 

#endif
