#ifndef SAMSONTRACE_
#define SAMSONTRACE_

#include "ISE.h"

#include "DispatcherConfig.h"

#include <map>
#include <list>
#include <string>
#include <sstream>

#include <boost/shared_ptr.hpp>

#include "auto.h"

#include "PeerRoute.h"
#include "ConnectionHandler.h"

namespace Samson_Peer {


// ===========================================================================
/**
	@author Jack Lavender <jack.lavender@lmco.com>
*/

struct SamsonTraceRecord
{
	SamsonHeader sh_;
	std::list<Samson_Peer::PeerRoute> sl_;
	std::list<int> sr_;

	// ---------------------------------------------------------------------
	void print (void) const
	{
		ACE_DEBUG ((LM_DEBUG, "%s\n", (this->report()).c_str()));
	}


	// ----------------------------------------------------------------
	std::string report (void) const
	{
		boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

		*my_report << sh_.report();

		for(AUTO(i,sl_.begin()); i != sl_.end(); ++i)
		{
			*my_report << std::endl <<(*i).report();
		}

		for(AUTO(i,sr_.begin()); i != sr_.end(); ++i)
		{
			*my_report << std::endl << "remote: " << (*i);
		}

		return my_report->str();
	}
};

class SamsonTraceList
{
	private:
		std::list<SamsonTraceRecord> str_;

	public:
		void add(SamsonTraceRecord *tr)
		{
			str_.push_front(*tr);
			if ( str_.size() > 25 ) str_.pop_back();
		}

		// ---------------------------------------------------------------------
		void print (void) const
		{
			ACE_DEBUG ((LM_DEBUG, "%s\n", (this->report()).c_str()));
		}

		// ----------------------------------------------------------------
		std::string report (void) const
		{
			boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

			for(AUTO(i,str_.begin()); i != str_.end(); ++i)
			{
				*my_report << (*i).report() << std::endl;
			}

			return my_report->str();
		}
};

class ISE_Export SamsonTrace
{
	private:
		mutable std::map<ConnectionHandler *,SamsonTraceList> tm_;

	public:

		void add(ConnectionHandler *rh, SamsonTraceRecord *tr)
		{
			tm_[rh].add(tr);
		}

		// ---------------------------------------------------------------------
		void print (ConnectionHandler *rh) const
		{
			ACE_DEBUG ((LM_DEBUG, "%s\n", (this->report(rh)).c_str()));
		}

		// ----------------------------------------------------------------
		std::string report (ConnectionHandler *rh) const
		{
			boost::shared_ptr<std::stringstream> my_report(new std::stringstream);
			*my_report << "Connection Handler:"  << std::hex << long(rh) << std::dec << std::endl;
			*my_report << tm_[rh].report();
			return my_report->str();
		}
};

} // namespace

#endif /*SAMSONTRACE_*/
