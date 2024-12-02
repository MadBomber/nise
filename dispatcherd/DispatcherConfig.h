#ifndef DISPATCHERCONFIG_H_
#define DISPATCHERCONFIG_H_

#include "ISE.h"

#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

//typedef ACE_Null_Mutex MAP_MUTEX;
typedef ACE_Recursive_Thread_Mutex MAP_MUTEX;

#endif /*DISPATCHERCONFIG_H_*/
