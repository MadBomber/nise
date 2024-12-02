// **********************************************************************
//
// Copyright (c) 2003-2007 ZeroC, Inc. All rights reserved.
//
// This copy of Ice is licensed to you under the terms described in the
// ICE_LICENSE file included in this distribution.
//
// **********************************************************************

#include <Ice/Ice.h>
#include <RandomServI.h>

using namespace std;

class RandomServServer : public Ice::Application
{
public:

    virtual int run(int, char*[]);
};

int
main(int argc, char* argv[])
{
    RandomServServer app;
    return app.main(argc, argv, "config.server");
}

int
RandomServServer::run(int argc, char* argv[])
{
    Ice::ObjectAdapterPtr adapter = communicator()->createObjectAdapter("RandomServ");
    adapter->add(new RandomServI, communicator()->stringToIdentity("randomserv"));
    adapter->activate();
    communicator()->waitForShutdown();
    return EXIT_SUCCESS;
}
