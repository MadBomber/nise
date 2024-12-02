
//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_ACE_Message_Block(const std::string& msg)
{
  int nchar=msg.length()+1;

  ACE_Message_Block *result =  new
    ACE_Message_Block (
      nchar,
      ACE_Message_Block::MB_DATA,
      0,
      0,
      0,
      0 //Options::instance ()->locking_strategy ()
      );

  result->copy(msg.c_str(), nchar);
  return result;
}

//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_ACE_Message_Block_as_HTTP(const std::string& msg, int rtncode)
{
  std::string hdr("HTTP/1.1 "+boost::lexical_cast<std::string>(rtncode)+ " OK\n" +
	"Content-Length: "+boost::lexical_cast<std::string>(msg.length())+"\n\n");
  return create_ACE_Message_Block(hdr+msg+'\n');
}

/*
//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_404()
{
  std::string msg(
      "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">"
      "<HTML><HEAD>"
      "<TITLE>404 Not Found</TITLE>"
      "</HEAD><BODY>"
      "<H1>Not Found</H1>"
      "The requested URL was not found on this server.<P>"
      "<HR>"
      "<ADDRESS>ISE dispatcher on port 8010</ADDRESS>"
      "</BODY></HTML>");
  return create_ACE_Message_Block_as_HTTP(msg,404);
}

//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_204()
{
	std::string msg("");
	return create_ACE_Message_Block_as_HTTP(msg,204);
}
*/

//..................................................................................
//..................................................................................
//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_ACE_Message_Block_Unified (const std::string& msg, const std::string& ctype, int rtncode)
{
	if(ctype=="text") {
		return create_ACE_Message_Block(msg);
	} else {
		std::string hdr("HTTP/1.1 "+boost::lexical_cast<std::string>(rtncode)+ " OK\n" +
			"Content-Length: "+boost::lexical_cast<std::string>(msg.length())+"\n\n");
		return create_ACE_Message_Block(hdr+msg+'\n');
	}
}

//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_OK (const std::string& ctype)
{
	if(ctype=="text") {
		const std::string data = "OK\n";
		return create_ACE_Message_Block(data);
	} else {
		std::string msg("");
		return create_ACE_Message_Block_as_HTTP(msg,204);
	}
}

//..................................................................................
ACE_INLINE
ACE_Message_Block* 
CommandParser::create_NOT_OK (const std::string& ctype)
{
	if(ctype=="text") {
		const std::string data = "FAILED\n";
		return create_ACE_Message_Block(data);
	} else {
		std::string msg(
		      "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">"
		      "<HTML><HEAD>"
		      "<TITLE>404 Not Found</TITLE>"
		      "</HEAD><BODY>"
		      "<H1>Not Found</H1>"
		      "The requested URL was not found on this server.<P>"
		      "<HR>"
		      "<ADDRESS>ISE dispatcher on port 8010</ADDRESS>"
		      "</BODY></HTML>");
		return create_ACE_Message_Block_as_HTTP(msg,404);
	}
}

