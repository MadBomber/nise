#!/usr/bin/sh
#######################################################################
###
##  File: install.s
##  Desc: Installs the configuration and resources files into their
##        designated locations.  This file typically only needs to be
##        executed once.
#

cp ./HOME/.roots $HOME/.roots
cat 'source ~/.roots' >> ~/.bashrc

