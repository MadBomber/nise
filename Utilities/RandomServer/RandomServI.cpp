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

RandomServI::RandomServI() :
    _byteSeq(IseRandom::ByteSeqSize),
    _stringSeq(IseRandom::StringSeqSize, "hello"),
    _structSeq(IseRandom::StringDoubleSeqSize),
    _fixedSeq(IseRandom::FixedSeqSize),
    _warmup(false)
{
    int i;
    for(i = 0; i < IseRandom::StringDoubleSeqSize; ++i)
    {
        _structSeq[i].s = "hello";
        _structSeq[i].d = 3.14;
    }
    for(i = 0; i < IseRandom::FixedSeqSize; ++i)
    {
        _fixedSeq[i].i = 0;
        _fixedSeq[i].j = 0;
        _fixedSeq[i].d = 0;
    }
}

bool
RandomServI::needsWarmup(const Ice::Current&)
{
    _warmup = false;
    return false;
}

void
RandomServI::startWarmup(const Ice::Current&)
{
    _warmup = true;
}

void
RandomServI::endWarmup(const Ice::Current&)
{
    _warmup = false;
}

void
RandomServI::sendByteSeq(const std::pair<const Ice::Byte*, const Ice::Byte*>&, const Ice::Current&)
{
}

IseRandom::ByteSeq
RandomServI::recvByteSeq(const Ice::Current&)
{
    if(_warmup)
    {
        return IseRandom::ByteSeq();
    }
    else
    {
        return _byteSeq;
    }
}

IseRandom::ByteSeq
RandomServI::echoByteSeq(const IseRandom::ByteSeq& seq, const Ice::Current&)
{
    return seq;
}

void
RandomServI::sendStringSeq(const IseRandom::StringSeq&, const Ice::Current&)
{
}

IseRandom::StringSeq
RandomServI::recvStringSeq(const Ice::Current&)
{
    if(_warmup)
    {
        return IseRandom::StringSeq();
    }
    else
    {
        return _stringSeq;
    }
}

IseRandom::StringSeq
RandomServI::echoStringSeq(const IseRandom::StringSeq& seq, const Ice::Current&)
{
    return seq;
}

void
RandomServI::sendStructSeq(const IseRandom::StringDoubleSeq&, const Ice::Current&)
{
}

IseRandom::StringDoubleSeq
RandomServI::recvStructSeq(const Ice::Current&)
{
    if(_warmup)
    {
        return IseRandom::StringDoubleSeq();
    }
    else
    {
        return _structSeq;
    }
}

IseRandom::StringDoubleSeq
RandomServI::echoStructSeq(const IseRandom::StringDoubleSeq& seq, const Ice::Current&)
{
    return seq;
}

void
RandomServI::sendFixedSeq(const IseRandom::FixedSeq&, const Ice::Current&)
{
}

IseRandom::FixedSeq
RandomServI::recvFixedSeq(const Ice::Current&)
{
    if(_warmup)
    {
        return IseRandom::FixedSeq();
    }
    else
    {
        return _fixedSeq;
    }
}

IseRandom::FixedSeq
RandomServI::echoFixedSeq(const IseRandom::FixedSeq& seq, const Ice::Current&)
{
    return seq;
}

void
RandomServI::shutdown(const Ice::Current& c)
{
    c.adapter->getCommunicator()->shutdown();
}
