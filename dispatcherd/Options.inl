ACE_INLINE
int
Options::enabled (int option) const
{
	return ACE_BIT_ENABLED (this->options_, option);
}

ACE_INLINE
void
Options::enable (int option)
{
	ACE_SET_BITS (this->options_, option);
}

ACE_INLINE
void
Options::disable (int option)
{
	ACE_CLR_BITS (this->options_, option);
}

ACE_INLINE
ACE_Lock_Adapter<ACE_SYNCH_MUTEX> *
Options::locking_strategy (void) const
{
	return this->locking_strategy_;
}

ACE_INLINE
void
Options::locking_strategy (ACE_Lock_Adapter<ACE_SYNCH_MUTEX> *ls)
{
	this->locking_strategy_ = ls;
}

ACE_INLINE
int
Options::performance_window (void) const
{
	return this->performance_window_;
}

ACE_INLINE
long
Options::max_timeout (void) const
{
	return this->max_timeout_;
}

ACE_INLINE
int
Options::blocking_semantics (void) const
{
	return this->blocking_semantics_;
}

ACE_INLINE
bool
Options::no_cache (void) const
{
	return this->no_cache_;
}

ACE_INLINE
int
Options::num_threads (void) const
{
	return this->num_threads_;
}

ACE_INLINE
u_long
Options::threading_strategy (void) const
{
	return this->threading_strategy_;
}

ACE_INLINE
const ACE_CString *
Options::initialization_file (void) const
{
	return &this->initialization_file_;
}

ACE_INLINE
const ACE_CString *
Options::initialization_key (void) const
{
	return &this->initialization_key_;
}

ACE_INLINE
const ACE_CString *
Options::pid_file (void) const
{
	return &this->pid_file_;
}

ACE_INLINE
u_short
Options::command_port (void) const
{
	return this->command_port_;
}

ACE_INLINE
u_short
Options::d2m_port (void) const
{
	return this->d2m_port_;
}

ACE_INLINE
u_short
Options::d2d_port (void) const
{
	return this->d2d_port_;
}

ACE_INLINE
long
Options::max_queue_size (void) const
{
	return this->max_queue_size_;
}

ACE_INLINE
long
Options::max_buffer_size (void) const
{
	return this->max_buffer_size_;
}

ACE_INLINE
bool
Options::isMaster(void)
{
return this->master_svc_;
}
