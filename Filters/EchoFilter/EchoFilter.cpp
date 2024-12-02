#define ISE_BUILD_DLL

#include "EchoFilter.h"
#include "LogLocker.h"
#include "DebugFlag.h"


namespace Samson_Peer {

int EchoFilter::init (int argc, ACE_TCHAR *argv[])
{
	if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) EchoFilter:init\n"));
	}
	return this->FilterBase::init(argc,argv);
}

int EchoFilter::fini (void)
{
	if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) EchoFilter:fini (%d of %d)\n",nmatch, ncalled));
	}

	return 1;
}
//...................................................................................................
int EchoFilter::info (ACE_TCHAR **info_string, size_t length) const
{
	std::stringstream myinfo;
	myinfo << *this;
	//this->toText(myinfo);

	if (*info_string == 0)
		*info_string = ACE::strnew(myinfo.str().c_str());
	else
		ACE_OS::strncpy(*info_string, myinfo.str().c_str(), length);

	return ACE_OS::strlen(*info_string) +1;
}


//...................................................................................................
ISE_Export ostream& operator<<(ostream& output, const EchoFilter& p)
{
    output << dynamic_cast< const EchoFilter&>(p) << std::endl;

    output << "EchoFilter:: ";
    output	<< " ncalled: " << p.ncalled;
    output	<< " nmatch: " << p.nmatch;
    return output;
}


//...................................................................................................
//...................................................................................................
//...................................................................................................
int EchoFilter::process( ACE_Message_Block * /*event*/, EventHeader * /*eh*/)
{
	ncalled++;
	return 1;
}

ACE_FACTORY_DECLARE(ISE,EchoFilter)

} // namespace
