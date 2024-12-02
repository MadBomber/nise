#ifndef _REVERSE_FILTER_HPP
#define _REVERSE_FILTER_HPP

#include "ISE.h"
#include "FilterBase.h"
#include "MessageBase.h"


//... boost smart pointers
#include <boost/scoped_ptr.hpp>

namespace Samson_Peer {


class ISE_Export ReverseFilter : public Samson_Peer::FilterBase
{
	public:
		ReverseFilter(void) {}
		~ReverseFilter(void) {}

		// to get state information
		virtual int info (ACE_TCHAR **info_string, size_t length) const;
		ISE_Export friend ostream& operator<<(ostream& output, const ReverseFilter& p);

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		virtual int process( ACE_Message_Block *event, EventHeader *eh);
};

ACE_FACTORY_DEFINE(ISE,ReverseFilter)

} // namespace

#endif

