#define ISE_BUILD_DLL

#include "ReverseFilter.h"
#include "LogLocker.h"
#include "DebugFlag.h"


namespace Samson_Peer {

int ReverseFilter::init (int argc, ACE_TCHAR *argv[])
{
	if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ReverseFilter:init\n"));
	}
	return this->FilterBase::init(argc,argv);
}

int ReverseFilter::fini (void)
{
	if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ReverseFilter:fini\n"));
	}

	return 1;
}
//...................................................................................................
int ReverseFilter::info (ACE_TCHAR **info_string, size_t length) const
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
ISE_Export ostream& operator<<(ostream& output, const ReverseFilter& p)
{
    output << dynamic_cast< const ReverseFilter&>(p) << std::endl;

    output << "ReverseFilter:: ";
    return output;
}


//...................................................................................................
//...................................................................................................
//...................................................................................................
int ReverseFilter::process (ACE_Message_Block *event, EventHeader *eh)
{
	if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ReverseFilter:process (%d|%d)\n",event->length(),eh->data_length()));
	}

	char *s = event->base();
	int n = event->length();

	for (int i=0; i<n; i++) if (islower(s[i])) s[i] = toupper(s[i]);

	return 1;
}

ACE_FACTORY_DECLARE(ISE,ReverseFilter)

} // namespace
