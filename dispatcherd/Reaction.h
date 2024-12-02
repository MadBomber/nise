/**
 *	@file Reaction.h
 * 
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef REACTION_SET_H
#define REACTION_SET_H

#include "ISE.h"

#include "DispatcherConfig.h"

#include "ace/Service_Config.h"
#include "ace/Containers.h"
#include "ace/SString.h"


namespace Samson_Peer {

// forward declaration
class ConnectionHandler;

// ==============================================================
class Reaction
{
public:
	Reaction(int id, char *name);
	virtual ~Reaction() {}

	void register_reaction (ConnectionHandler &ch);
	void remove_reaction (ConnectionHandler &ch);

	virtual void process(ConnectionHandler &ch) = 0;
	// Should I be using the SimEntity Representation ???

private:
	int id_;
	ACE_CString name_;
};

typedef ACE_Unbounded_Set<Reaction *> Reaction_Set;
typedef ACE_Unbounded_Set_Iterator<Reaction *> Reaction_Set_Iterator;

} // namespace

#endif

