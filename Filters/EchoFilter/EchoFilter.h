#ifndef _ECHO_FILTER_HPP
#define _ECHO_FILTER_HPP

#include "ISE.h"
#include "FilterBase.h"
#include "MessageBase.h"


//... boost smart pointers
#include <boost/scoped_ptr.hpp>

namespace Samson_Peer {


class ISE_Export EchoFilter : public Samson_Peer::FilterBase
{
	public:
		EchoFilter(void): ncalled(0), nmatch(0) {}
		~EchoFilter(void) {}

		// to get state information
		virtual int info (ACE_TCHAR **info_string, size_t length) const;
		ISE_Export friend ostream& operator<<(ostream& output, const EchoFilter& p);

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		virtual int process( ACE_Message_Block *event, EventHeader *eh);

	protected:

		int ncalled;
		int nmatch;

};

ACE_FACTORY_DEFINE(ISE,EchoFilter)

} // namespace

#endif

