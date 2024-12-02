// ==========================================================================
ACE_INLINE
int
PubSubDispatch::send_hello (ConnectionHandler *ch)
{
	return this->send_ctrl_event (ch, SimMsgType::HELLO);
}

// ==========================================================================
ACE_INLINE
const std::string
PubSubDispatch::attached_model_report ()
{
	return D2M_TABLE::instance()->report();
}

ACE_INLINE
const std::string
PubSubDispatch::message_report (ConnectionHandler *rh)
{
	return this->msg_trace_.report(rh);
}
