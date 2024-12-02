/**
 *	@file CommandParser.cpp
 *
 *  @brief Parser for command inputs
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "ISE.h"

#include "CommandParser.h"
#include "ConnectionHandler.h"
#include "TransceiverHandler.h"
#include "EventChannel.h"
#include "Service_ObjMgr.h"
#include "ConnectionTable.h"
#include "PubSubDispatch.h"
#include "XMLParser.h"
#include "IdentityTrace.h"
#include "SimTransform.h"
#include "DispatcherIdentity.h"
#include "CommandIdentity.h"
#include "SamsonMsgSender.h"
#include "DebugFlag.h"
#include "LogLocker.h"

#include <fstream>
#include <string>
#include <sstream>
#include <map>
#include <boost/any.hpp>
#include <boost/function.hpp>

#include <boost/spirit/include/classic_spirit.hpp>
#include <boost/algorithm/string/predicate.hpp>

#include <boost/lexical_cast.hpp>

#include "ace/OS_NS_stdio.h"
#include "ace/OS_NS_string.h"
#include "ace/OS_NS_unistd.h"
#include "ace/Service_Config.h"
#include "ace/Signal.h"
#include "ace/Log_Msg.h"

static int process_retval = 0;


// I really have mixed feelings about using
using namespace std;
using namespace boost::spirit::classic;
using boost::any_cast;
using boost::any;

typedef std::multimap<string,boost::any> many;
typedef boost::function<ACE_Message_Block * (many&,std::string&)> Action_t;

namespace {
  std::string RootPath = ACE_OS::getenv("ISE_ROOT");
  std::string HtmlPath = RootPath+"/www/html/";

  struct SetAction
  {
    SetAction(Action_t& the_action) : m_the_action(the_action) {}
    void operator()(Action_t* new_action) const
    {
      m_the_action = *new_action;
    }
  private:
    Action_t& m_the_action;
  };

  bool is_bool(const boost::any & operand)   { return operand.type() == typeid(bool);   }
  bool is_int(const boost::any & operand)    { return operand.type() == typeid(int);    }
  bool is_real(const boost::any & operand)   { return operand.type() == typeid(double); }
  bool is_string(const boost::any & operand) { return operand.type() == typeid(string); }


//--------------------------------------------------------
ACE_Message_Block * nvprint(many& nv, std::string& ext)
{
	stringstream my_cout;

	my_cout<<"sizeof nv: "<<nv.size()<<endl;
	for(typeof(nv.begin()) it=nv.begin(); it!=nv.end(); ++it) {
		my_cout<<it->first<<": ";
		if(is_bool(it->second))   my_cout << "(b) " << (any_cast<bool>(it->second)? "true":"false");
		if(is_int(it->second))    my_cout << "(i) " << any_cast<int>(it->second);
		if(is_real(it->second))   my_cout << "(r) " << any_cast<double>(it->second);
		if(is_string(it->second)) my_cout << "(s) " <<  any_cast<string>(it->second);
		my_cout <<endl;
	}

	ACE_Message_Block *retval = 0;

	if(ext=="xml" || ext=="html" || ext=="htm") {
			retval = Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_as_HTTP(my_cout.str());
	} else {
			retval = Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block(my_cout.str());
	}
	return retval;
}

ACE_Message_Block * nv_job         (many& nv, std::string ext) {cout<<"job"         << endl; return nvprint(nv,ext); }


//--------------------------------------------------------
ACE_Message_Block * send_file(const char *b, const char *e)
{
	using boost::algorithm::iends_with;
	std::string filename=(b==e)?"index.html":std::string(b,e);
        std::string ext("text");
        if(iends_with(filename, ".xml"))  ext="xml"; else
        if(iends_with(filename, ".xsl"))  ext="xsl"; else
        if(iends_with(filename, ".htm"))  ext="htm"; else
        if(iends_with(filename, ".html")) ext="html";
//  {string s(b,e); ACE_DEBUG ((LM_DEBUG,"send_file(): %s  %s\n", s.c_str(), (HtmlPath+filename).c_str()));}
	if(ext=="xml" || ext=="html" || ext=="htm" || ext=="xsl")
	{
		std::ifstream is((HtmlPath+filename).c_str());
		if(is)
		{
			std::string str;
			copy(std::istreambuf_iterator<char>(is),std::istreambuf_iterator<char>(),std::back_inserter(str));
			//ACE_DEBUG ((LM_DEBUG, "CommandParser->nv_unknown Function %s\n", str.c_str()));
			return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_as_HTTP(str);
		}
		else
		{
			//ACE_DEBUG ((LM_DEBUG, "CommandParser->nv_unknown Function NOT OK\n"));
			return Samson_Peer::COMMAND_PARSER::instance ()->create_NOT_OK(ext);
		}
	} else {
		many nv;
		return nvprint(nv,ext);
	}
}

ACE_Message_Block * nv_kill(many& nv, std::string& ext)
{
	for(typeof(nv.begin()) it=nv.begin(); it!=nv.end(); ++it)
	{
		if ( it->first == "job" &&  is_int(it->second) )
		{
			Samson_Peer::TransceiverHandler *ch = dynamic_cast<Samson_Peer::TransceiverHandler *>(Samson_Peer::COMMAND_PARSER::instance ()->get_connection_handler());

			unsigned int flag = SimMsgFlag::status_log_local;
			//flag |= SimMsgFlag::status_log_dispatcherd;
			//flag |= SimMsgFlag::status_log_sender;

			Samson_Peer::SamsonMsgSender::sendCtrlMsgToJob (any_cast<int>(it->second), SimMsgType::GOODBYE_REQUEST , flag, ch);
		}
		else if ( it->first == "model" &&  is_int(it->second) )
		{
			Samson_Peer::TransceiverHandler *ch = dynamic_cast<Samson_Peer::TransceiverHandler *>(Samson_Peer::COMMAND_PARSER::instance ()->get_connection_handler());

			unsigned int flag = SimMsgFlag::status_log_sender;
			Samson_Peer::SamsonMsgSender::sendCtrlMsgToModel (any_cast<int>(it->second), SimMsgType::GOODBYE_REQUEST,flag, ch);
		}
	}
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}

//--------------------------------------------------------
ACE_Message_Block * nv_status(many& nv, std::string& ext)
{
	for(typeof(nv.begin()) it=nv.begin(); it!=nv.end(); ++it)
	{
		if ( it->first == "job" &&  is_int(it->second) )
		{
			Samson_Peer::TransceiverHandler *ch = dynamic_cast<Samson_Peer::TransceiverHandler *>(Samson_Peer::COMMAND_PARSER::instance ()->get_connection_handler());

			unsigned int flag = SimMsgFlag::status_log_local;
			//flag |= SimMsgFlag::status_log_dispatcherd;
			//flag |= SimMsgFlag::status_log_sender;

			Samson_Peer::SamsonMsgSender::sendCtrlMsgToJob (any_cast<int>(it->second), SimMsgType::STATUS_REQUEST , flag, ch);
		}
		else if ( it->first == "model" &&  is_int(it->second) )
		{
			Samson_Peer::TransceiverHandler *ch = dynamic_cast<Samson_Peer::TransceiverHandler *>(Samson_Peer::COMMAND_PARSER::instance ()->get_connection_handler());

			unsigned int flag = SimMsgFlag::status_log_sender;
			Samson_Peer::SamsonMsgSender::sendCtrlMsgToModel (any_cast<int>(it->second), SimMsgType::STATUS_REQUEST,flag, ch);
		}
	}
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}


ACE_Message_Block * nv_opt (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::Options::instance()->report();
	} else {
		data = Samson_Peer::Options::instance()->report_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_d2c (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::D2C_TABLE::instance()->report();
	} else {
		data = Samson_Peer::D2C_TABLE::instance()->report_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_d2d (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::D2D_TABLE::instance()->report();
	} else {
		data = Samson_Peer::D2D_TABLE::instance()->report_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_d2m (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::D2M_TABLE::instance()->report();
	} else {
		data = Samson_Peer::D2M_TABLE::instance()->report_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_rcv_conn (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::CONNECTION_TABLE::instance()->status_recv_connections();
	} else {
		data = Samson_Peer::CONNECTION_TABLE::instance()->status_recv_connections_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_connections (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data=Samson_Peer::CONNECTION_TABLE::instance ()->status_connections();
	} else {
		data=Samson_Peer::CONNECTION_TABLE::instance ()->status_connections_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_acceptors (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::CONNECTION_TABLE::instance ()->status_acceptors();
	} else {
		data = Samson_Peer::CONNECTION_TABLE::instance ()->status_acceptors_xml ();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block * nv_ctable (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
		data = Samson_Peer::CONNECTION_TABLE::instance ()->print_ctable();
	} else {
		data = Samson_Peer::CONNECTION_TABLE::instance()->print_ctable_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block *nv_identity (many&, std::string& ext)
{
	std::string data;

	if(ext=="text") {
			data=Samson_Peer::SAMSON_OBJMGR::instance ()->report();
	} else {
			data=Samson_Peer::SAMSON_OBJMGR::instance ()->report_xml();
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_Unified (data, ext);;
}

ACE_Message_Block *nv_alive (many&, std::string& ext)
{
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}

ACE_Message_Block * nv_disconnect (many&, std::string& ext)
{
	process_retval = 1;
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}

ACE_Message_Block * nv_quit (many&, std::string& ext)
{
	ACE_Reactor::end_event_loop();
	process_retval = 1;
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);

}

ACE_Message_Block * nv_anneal (many&, std::string& ext)
{
	Samson_Peer::EVENT_CHANNEL_MGR::instance ()->initiate_all_d2d_connections();
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}

ACE_Message_Block * nv_verbose (many&, std::string& ext)
{
	//(Samson_Peer::Options::instance ()->enabled(Samson_Peer::Options::VERBOSE)) ?
			//Samson_Peer::Options::instance ()->disable(Samson_Peer::Options::VERBOSE) :
			//Samson_Peer::Options::instance ()->enable(Samson_Peer::Options::VERBOSE);

	static bool debug_ = false;

	if ( debug_ )
	{
		 Samson_Peer::DebugFlag::instance ()->off();
		 debug_ = false;
	}
	else
	{
		Samson_Peer::DebugFlag::instance ()->on();
		debug_ = true;
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}

ACE_Message_Block * nv_trace (many&, std::string& ext )
{
	(ACE_Trace::is_tracing()) ? ACE_Trace::stop_tracing() : ACE_Trace::start_tracing();
	return Samson_Peer::COMMAND_PARSER::instance ()->create_OK(ext);
}

ACE_Message_Block * nv_stats (many&, std::string& ext )
{
	const std::string data = Samson_Peer::EVENT_CHANNEL_MGR::instance ()->compute_performance_statistics(0);

	if(ext=="xml" || ext=="html" || ext=="htm") {
		std::ostringstream os;
		os << "<pre>\n" << data << "\n</pre>\n";
		return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block_as_HTTP(os.str());
	}

	return Samson_Peer::COMMAND_PARSER::instance ()->create_ACE_Message_Block(data);
}


//--------------------------------------------------------
Action_t acceptors_a   = &nv_acceptors   ;
Action_t ctable_a      = &nv_ctable      ;
Action_t command_a     = &nv_d2c         ;
Action_t connections_a = &nv_connections ;
Action_t rcv_conn_a    = &nv_rcv_conn    ;
Action_t d2m_a         = &nv_d2m         ;
Action_t d2d_a         = &nv_d2d         ;
Action_t id_a          = &nv_identity    ;
Action_t opt_a         = &nv_opt         ;
Action_t anneal_a      = &nv_anneal      ;
Action_t job_a         = &nv_job         ;
Action_t trace_a       = &nv_trace       ;
Action_t verbose_a     = &nv_verbose     ;
Action_t disconnect_a  = &nv_disconnect  ;
Action_t quit_a        = &nv_quit        ;
Action_t status_a      = &nv_status      ;
Action_t stats_a       = &nv_stats       ;
Action_t kill_a        = &nv_kill        ;
Action_t alive_a       = &nv_alive       ;

//--------------------------------------------------------
symbols<Action_t*> create_action_table()
{
	symbols<Action_t*> action_table;

	action_table.add
	("acceptors",    &acceptors_a   )
	("ctable",       &ctable_a      )
	("command",      &command_a     )
	("connections",  &connections_a )
	("rcv_conn",     &rcv_conn_a    )
	("models",       &d2m_a         )
	("dispatchers",  &d2d_a         )
	("identity",     &id_a          )
	("opt",          &opt_a         )
	("anneal",       &anneal_a      )
	("job",          &job_a         )
	("status",       &status_a      )
	("stats",        &stats_a       )
	("kill",         &kill_a        )
	("trace",        &trace_a       )
	("verbose",      &verbose_a     )
	("disconnect",   &disconnect_a  )
	("d",            &disconnect_a  )
	("alive",        &alive_a       )
	("options",      &opt_a         )
	("quit",         &quit_a        );

	return action_table;
}

} //namespace (anonymous)




namespace Samson_Peer
{

#if !defined (__ACE_INLINE__)
#include "CommandParser.inl"
#endif /* __ACE_INLINE__ */



// ===========================================================================
void CommandParser::cmd_status(ACE_HANDLE h, ACE_Message_Block *report_mb)
{
	ConnectionHandler *ch = 0;

	// stdin interface is not used much anymore
	if (h == ACE_STDIN)
	{
		LogLocker log_lock;

		// I "know" it is null terminated ;)
		ACE_DEBUG((LM_DEBUG, "%s", report_mb->base()));
		report_mb->release();
	}

	// when the reply caused a message to be sent onwards....
	else if ( (ch = D2C_TABLE::instance()->getCHfromCHID(h)) != 0)
	{
		//ACE_DEBUG ((LM_DEBUG, "Cmd Result 3: <<\n%s\n>>", report_mb->base()));
		ACE_DEBUG ((LM_DEBUG, "D2C on Handle: %d\n", h));

		TransceiverHandler *rh = 0;

		// Sometimes the handle closes. and stuff just does not work
		try
		{
			rh = dynamic_cast<TransceiverHandler *>(ch);
		}
		catch (bad_cast& bc)
		{
			ACE_DEBUG ((LM_ERROR, "Bad cast on Handle: %d %s\n", h, bc.what()));
			return;
		}


		if (rh && rh->put(report_mb) == -1)
		{
			if (errno == EWOULDBLOCK) // The queue has filled up!
				ACE_ERROR((
						LM_ERROR,
						"(%P|%t) CommandParser::st -> %p\n",
						"gateway is flow controlled, so we're dropping events on %d:%d",
						rh->connection_id(), rh->get_handle()));
			else
				ACE_ERROR((
						LM_ERROR,
						"(%P|%t) CommandParser::st -> %p transmission error to peer %d:%d\n",
						"put", rh->connection_id(), rh->get_handle()));

			// If an error occured, we are responsible for cleaning up.
			report_mb->release();
		}

	}

	// when a reply comes from the dispatcher reply to the sender
	//	TODO  if the channel uses a header...what do I do ????
	//	NOTE:  cmd_status is a static function, so must use get_connection_handler to get my_ch_
	else if (COMMAND_PARSER::instance ()->get_connection_handler() != 0)
	{
#if 0
		//ACE_DEBUG ((LM_DEBUG, "Cmd Result 2: <<\n%s\n>>", report_mb->base()));
		ACE_DEBUG ((LM_DEBUG, "my_ch_ on Handle: %d\n", h));

		TransceiverHandler *rh =
				dynamic_cast<TransceiverHandler *>(COMMAND_PARSER::instance ()->get_connection_handler());

		if (rh && rh->put(report_mb) == -1)
		{
			if (errno == EWOULDBLOCK) // The queue has filled up!
				ACE_ERROR((
						LM_ERROR,
						"(%P|%t) CommandParser::st -> %p\n",
						"gateway is flow controlled, so we're dropping events on %d:%d",
						rh->connection_id(), rh->get_handle()));
			else
				ACE_ERROR((
						LM_ERROR,
						"(%P|%t) CommandParser::st -> %p transmission error to peer %d:%d\n",
						"put", rh->connection_id(), rh->get_handle()));

			// If an error occured, we are responsible for cleaning up.
			report_mb->release();
		}
#endif
	}


	// the reply is going NOWHERE  TODO:  Throw an error ???
	else
	{
		LogLocker log_lock;

		ACE_DEBUG((LM_DEBUG, "Cmd Result default: <<\n%s\n>>",
				report_mb->base()));
		ACE_DEBUG((LM_DEBUG, " on Handle: %d\n", h));
	}

	return;
}

// ===========================================================================
int CommandParser::process(ConnectionHandler *rh, ACE_Message_Block *event)
{

	SimTransform dater1 = SimTransform(event->rd_ptr(), event->length());
	dater1.make_printable();

	if ( DebugFlag::instance ()->enabled (DebugFlag::CMD_DEBUG) )
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,"Block made Printable(%d):<<%s>>\n", dater1.nresult(), dater1.result()));
	}

	this->my_ch_ = rh;
	ACE_HANDLE h = rh->get_handle();
	int result = this->process(dater1.result(), h);
	this->my_ch_ = 0;

	//if ( DebugFlag::instance ()->enabled (DebugFlag::CMD_DEBUG) )
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG, "CommandParser::process (%s) returning %d on (%d|0x%x)\n", dater1.result(), result, rh->get_handle(), rh));
	}

	return result;
}

// ===========================================================================
// ===========================================================================
// ===========================================================================

class Action
{
public:
  Action(many& nv, Action_t& action_a, std::string ext, ACE_HANDLE h):nv(nv),action_a(action_a),ext(ext),h(h){nv.clear();}
  void operator()(const char *, const char *) const
  {
    //string s(b,e);
    //ACE_DEBUG ((LM_DEBUG,"Action(): %s\n", s.c_str()));
    CommandParser::cmd_status(h, action_a(nv,ext));
  }
private:
  many& nv;
  Action_t& action_a;
  std::string& ext;
  ACE_HANDLE h;
};

class Assign
{
public:
  Assign(many& nv,std::string& key):nv(nv),key(key){}
  void operator()(const char *b, const char *e) const
  {
    std::string s(b,e);
    if(s=="true") nv.insert(std::make_pair(key,true));
    else if(s=="false") nv.insert(std::make_pair(key,false));
    else nv.insert(std::make_pair(key,s));
  }
  void operator()(double v) const {nv.insert(std::make_pair(key,any(v)));}
  void operator()(int v) const {nv.insert(std::make_pair(key,any(v)));}
private:
  many& nv;
  std::string& key;
};

class Unknown
{
public:
  Unknown(ACE_HANDLE h):h(h){}
  void operator()(const char *b, const char *e) const {CommandParser::cmd_status(h, send_file(b,e));}
private:
  ACE_HANDLE h;
};

// ===========================================================================
int CommandParser::process( const char *buf, ACE_HANDLE h)
{
	process_retval = 0;
  many nv;

  static symbols<Action_t*> action_table = create_action_table();

  Action_t action_a;
  std::string key;
  std::string ext="text";
  std::string htm_ext="html";

  Action  nv_a(nv,action_a,ext,h);
  Assign  val_a(nv,key);
  Unknown unk_a(h);

  rule<> GET     = *space_p >> as_lower_d["get"] >> +space_p >> ch_p('/');
  rule<> UNKNOWN = (*(anychar_p-'?'-blank_p))[unk_a] >> *anychar_p;
  rule<> bool_p  = (str_p("true")|"false");
  rule<> kv_p    = ((*(anychar_p-'='))[assign_a(key)]>>'='>> (strict_real_p[val_a]| int_p[val_a]| bool_p[val_a]| (*(anychar_p-','-'&'))[val_a])%ch_p(','))%'&';
  rule<> opts    = ch_p('?')>>kv_p;
  rule<> exts    = ch_p('.')>>(str_p("xml")|"html"|"htm")[assign_a(ext)];
  rule<> r       = !GET[assign_a(ext,htm_ext)] >> ((action_table[SetAction(action_a)] >> (exts || opts || space_p) >> *anychar_p )[nv_a]
                                 | UNKNOWN);

  parse(buf, r);

	if ( process_retval < 0 )
	{
		process_retval = 1;
		ACE_Reactor::end_event_loop();  // TODO:  this seems abrupt, is there a "preferred" way to shutdown which does not short circuit the call.
	}

	return process_retval;
}

// ==========================================================================
int
CommandParser::initialize (void)
{
	ACE_TRACE("CommandParser::initialize");
	return 0;
}

// ==========================================================================
CommandParser::~CommandParser()
{
	ACE_TRACE("CommandParser::~CommandParser");
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~CommandParser called.\n"));
#endif
}

}  // namespace
