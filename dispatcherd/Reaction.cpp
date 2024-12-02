#include "Reaction.h"
#include "ConnectionHandler.h"

namespace Samson_Peer {

// ===========================================================================
Reaction::Reaction(int id, char *name)
{
	this->id_ = id;
	this->name_.set(name);
}

// ===========================================================================
void
Reaction::register_reaction (ConnectionHandler &ch)
{
	ch.register_reaction(this);
}

// ===========================================================================
void
Reaction::remove_reaction (ConnectionHandler &ch)
{
	ch.remove_reaction(this);
}

} // namespace
