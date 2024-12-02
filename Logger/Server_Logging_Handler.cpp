/* -*- C++ -*- */

#if !defined (ISE_SERVER_LOGGING_HANDLER_C)
#define ISE_SERVER_LOGGING_HANDLER_C

#define ACE_BUILD_SVC_DLL

#include "Server_Logging_Handler.h"


// The following are "Factories" used by the ACE_Service_Config and
// svc.conf file to dynamically initialize the state of the
// single-threaded and multi-threaded logging server.

ACE_SVC_FACTORY_DEFINE (ISE_Server_Logging_Acceptor)
ACE_SVC_FACTORY_DEFINE (ISE_Thr_Server_Logging_Acceptor)

#if defined (ACE_HAS_EXPLICIT_STATIC_TEMPLATE_MEMBER_INSTANTIATION)
template ISE_Server_Logging_Handler_T<LOGGING_PEER_STREAM,
                                      u_long,
                                      ACE_NULL_SYNCH,
                                      Null_Synch_Static_Receiver> *
  ISE_Server_Logging_Handler_T<LOGGING_PEER_STREAM,
                               u_long,
                               ACE_NULL_SYNCH,
                               Null_Synch_Static_Receiver>::request_count_;
#endif /* ACE_HAS_EXPLICIT_STATIC_TEMPLATE_MEMBER_INSTANTIATION */
#endif /* ISE_SERVER_LOGGING_HANDLER_C */

