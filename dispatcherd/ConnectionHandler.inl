namespace Samson_Peer
{

// ==========================================================================
inline void ConnectionHandler::total_bytes_send(size_t bytes)
{
	send_stats.sample(bytes);
}

// ==========================================================================
inline void ConnectionHandler::total_bytes_recv(size_t bytes)
{
	recv_stats.sample(bytes);
}

// = Gets the max timeout delay.
inline unsigned int ConnectionHandler::max_timeout(void) const
{
	return this->entity_->max_retry_timeout_;
}

// = Gets the first message alert logical .
inline bool ConnectionHandler::first_message_alert(void) const
{
	return this->entity_->first_message_alert_;
}

// = Get the Connection Role.
inline char ConnectionHandler::proxy_role(void) const
{
	return this->entity_->proxy_role_;
}

// = Set/get remote INET addr.
inline const ACE_INET_Addr &ConnectionHandler::remote_addr(void) const
{
	return this->remote_addr_;
}

inline void ConnectionHandler::remote_addr(ACE_INET_Addr &ra)
{
	this->remote_addr_ = ra;
}

// = Set/get local INET addr.
inline const ACE_INET_Addr &ConnectionHandler::local_addr(void) const
{
	return this->local_addr_;
}
inline void ConnectionHandler::local_addr(ACE_INET_Addr &la)
{
	this->local_addr_ = la;
}

// = Set/Get the state of the Proxy.
inline void ConnectionHandler::state(ConnectionHandler::State s)
{
	this->state_ = s;
}
inline ConnectionHandler::State ConnectionHandler::state(void) const
{
	return this->state_;
}

// = Gets the connection header id.
inline int ConnectionHandler::header_type_id(void) const
{
	return this->header_type_id_;
}

// = Get the Connection ID
inline ACE_INT32 ConnectionHandler::connection_id(void) const
{
	return this->connection_id_;
}

// = Get the Connection Role.
inline bool ConnectionHandler::command_role(void) const
{
	return this->entity_->proxy_role_ == 'C';
}

// = Get the Connection Type.
inline char ConnectionHandler::connection_type(void) const
{
	return this->entity_->connection_type_;
}

// = Sets the connection retry timeout
inline unsigned int ConnectionHandler::read_buff(void) const
{
	return this->entity_->read_buff;
}

// = Sets the connection retry timeout
inline void ConnectionHandler::timeout(unsigned int to)
{
	this->timeout_
			= (to > this->entity_->max_retry_timeout_ ) ? this->entity_->max_retry_timeout_
					: to;
}

// ==========================================================================
inline bool ConnectionHandler::passive(void)
{
	return this->entity_->connection_type_ != 'A';
}

// ==========================================================================
// Add a Reaction to the set

inline void ConnectionHandler::register_reaction(Reaction *re)
{
	this->active_reaction_list_.insert(re);
}

// ==========================================================================
// Remove a Reaction from the set

inline void ConnectionHandler::remove_reaction(Reaction *re)
{
	this->active_reaction_list_.remove(re);
}

} // namespace
