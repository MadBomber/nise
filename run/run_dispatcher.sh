#!/bin/sh
export LD_LIBRARY_PATH=.:../lib:$ACE_ROOT/lib
cd ../dispatcherd
pwd
./dispatcherd -f xml/ise1.xml
