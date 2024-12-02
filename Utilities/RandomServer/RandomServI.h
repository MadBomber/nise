// **********************************************************************
//
// Copyright (c) 2003-2007 ZeroC, Inc. All rights reserved.
//
// This copy of Ice is licensed to you under the terms described in the
// ICE_LICENSE file included in this distribution.
//
// **********************************************************************

#ifndef RANDOMSERV_I_H
#define RANDOMSERV_H

#include <RandomServ.h>

class RandomServI : public IseRandom::RandomServ
{
public:

    RandomServI();

    virtual bool needsWarmup(const Ice::Current&);
    virtual void startWarmup(const Ice::Current&);
    virtual void endWarmup(const Ice::Current&);
    virtual void sendByteSeq(const std::pair<const Ice::Byte*, const Ice::Byte*>&, const Ice::Current&);
    virtual IseRandom::ByteSeq recvByteSeq(const Ice::Current&);
    virtual IseRandom::ByteSeq echoByteSeq(const IseRandom::ByteSeq& seq, const Ice::Current&);
    virtual void sendStringSeq(const IseRandom::StringSeq&, const Ice::Current&);
    virtual IseRandom::StringSeq recvStringSeq(const Ice::Current&);
    virtual IseRandom::StringSeq echoStringSeq(const IseRandom::StringSeq& seq, const Ice::Current&);
    virtual void sendStructSeq(const IseRandom::StringDoubleSeq&, const Ice::Current&);
    virtual IseRandom::StringDoubleSeq recvStructSeq(const Ice::Current&);
    virtual IseRandom::StringDoubleSeq echoStructSeq(const IseRandom::StringDoubleSeq& seq, const Ice::Current&);
    virtual void sendFixedSeq(const IseRandom::FixedSeq&, const Ice::Current&);
    virtual IseRandom::FixedSeq recvFixedSeq(const Ice::Current&);
    virtual IseRandom::FixedSeq echoFixedSeq(const IseRandom::FixedSeq& seq, const Ice::Current&);
    virtual void shutdown(const Ice::Current& c);

private:

    IseRandom::ByteSeq _byteSeq;
    IseRandom::StringSeq _stringSeq;
    IseRandom::StringDoubleSeq _structSeq;
    IseRandom::FixedSeq _fixedSeq;

    bool _warmup;
};

#endif
