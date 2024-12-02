#ifndef _CBASEMSG_H_
#define _CBASEMSG_H_

//....boost serialization
#include <boost/archive/basic_xml_archive.hpp>
#include <boost/archive/xml_oarchive.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/version.hpp>
#include <boost/serialization/nvp.hpp>
#include <boost/serialization/utility.hpp>
#include <boost/serialization/string.hpp>


////////////////////////////////////////////////////////////////////////////////
// Defines                                                                    //
////////////////////////////////////////////////////////////////////////////////
enum SMessageType
{
	SM_Null = 0,
	SM_LoadInput = 1,
	SM_RemoteSetup = 2,
	SM_Initialization = 3,
	SM_ReInitialization = 4,
	SM_Execute = 5,
	SM_TimeGrant = 6,
	SM_Terminate = 7,
	SM_TargetStates = 8,
	SM_EndFrame = 9
};

///////////////////////////////////////////////////////////////////////////// 
//
///////////////////////////////////////////////////////////////////////////// 
class CBaseMsg
{ 
public:
	CBaseMsg(); 
	CBaseMsg(SMessageType, std::string, std::string); 

	// Attributes 
public: 
	//CMutex			m_Mutex;							// Synchronization
	int				m_iMsgID;							// Unique Message ID
	SMessageType	m_sMsgType;							// Message Type
	std::string	Key;
	std::string	Description;

// Operations 
	void SetMsgID(int iMsgID);							// Sets a unique identifier to each message.
	int GetMsgID() const;								// Gets the identifier of this message.
	void SetMessageType(SMessageType sMsgType);
	SMessageType GetMessageType() const;

	CBaseMsg& operator=(const CBaseMsg& msg);	// assignment
	void Copy(const CBaseMsg& msg);

	// Implementation
	virtual ~CBaseMsg();

	friend class boost::serialization::access;
	template<class Archive>
	void serialize(Archive &ar, const unsigned int) 
	{
		ar & BOOST_SERIALIZATION_NVP(m_iMsgID);
		ar & BOOST_SERIALIZATION_NVP(m_sMsgType);
	}

};

class CISEReplyMsg : public CBaseMsg
{
public:
	CISEReplyMsg()  : 
		CBaseMsg(SM_EndFrame,std::string("ISEReply"),std::string("a really nice reply message")) {}

protected:
        friend class boost::serialization::access;
        template<class Archive>
        void serialize(Archive &ar, const unsigned int)
        {
                ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(CBaseMsg);
        }
};
#endif 
