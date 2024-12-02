##########################################################
###
##  File: README.txt
##  Desc: Provide basic getting started information
#

**NOTE** This is some very old code retrieved from
from an my old archive on BitBucket.  I've moved it to 
GitHub as part of an archive consolidation.  My intent is
to pick out the old Ruby components and modernize them.

Instructions to building the Next ISE (NISE) and its Models

POSIXish platforms:

  iserelease.s


MS Windows:

  Microsoft Operating Systems are not supported

########
# TODO: update the outdated material.  Use the ISEwiki for source text; updating the wiki as necessary.

What is ISE

ISE (Integrated Systems Environment) is a framework built upon open-source
toolkits, e.g., ACE, boost, Ruby on Rails.  

Authors:
  Dewaynve VanHoozer
  Jack K Lavender, Jr
  April 23, 2009

Documentation and Code

All the code and documentation (including this file) are stored in a
Subversion Repository.  


Requirements for this version
ACE 5.7.1+  
MySQL 5.1+
Ruby (with gems added in the Gemfile, used by bundler...read the header in Gemfile for installation instructions ) 

Recommendataions (or pending requirements)
Apache 2+
phpMyAdmin



To simplify OS system and cluster management package management systems were
used.  Such as RPM's for the Redhat/Fedora systems.  To see the current packages 
on the different PCs view files in the Packages directory.

This repository used to contain the Samson Example Models, they are 
now in a seperate directory.

This application is database centric. This is currently configured for MySQL
but this should port to any relational database. 

You need to have a MySQL Database running.  Create a Samson user/table and
import the  SAMSON.sql file to create the database.  A sample  my.cnf file
that will setup the application to work.  In linux copy it to ~/.my.cnf with
600 permission and it will work.  Getting the client to work on windows is
trickier, put a  my.ini or my.cnf into the %WINDIR% (usually C:\WINDOWS). It
myst contain both a [client] and [Samson].  The case insensitivity of windows
will provide a bit of diversion if you are not careful.

Database Specifics
------------------

# TODO: Update database initialization sequence

POSIXish Platform:

  # From a bash shell with $ACE_ROOT defined do:
  source setup_symbols.sh
  rake db:drop             ## drops the Delilah IseDatabase
  rake db:migrate          ## updates the IseDatabase schema to latest version
  rake db:schema:dump      ## creates db/schema.rb file for rapid bootstrap
  rake db:bootstrap:load   ## loads initial content from db/bootstrap

MS Windows:

  TBD

Setup Runtime Environment
-------------------------

This is for both Windows and Linux.  I do not have any scripts
created for Windows.  I will assume you have built ACE and have setup
the ACE_ROOT environment variable.  However to make that easier,
put the edit and place the included etc/profile.d/ACE.sh in its 
proper location.

Note:  LD_LIBRARY_PATH is a tricky variable that is being masked
out by many environments. Not sure what reliable mechanism to use
to put shared libraries where they will be accessible.

To make it easier, I have created a script to create some handy 
environment variables.

$ . setup_symbols
(current being run out of the .bashrc file)

Run
---

This is two parts for now,  daemons and application
The daemon work is underway, so as an interim solution

$ dispatcher -s

used to start the ISE  Dispatcher

$  ise -c1

To run stored job 1  ( $ ise -j  => shows all jobs)

The output is under the "output" directory under a "guid" that uniquely 
defines this run,  it is printed out when you execut the runjob script.

You can telnet into the dispatcher or open with web client

$ telnet 127.0.0.1 8010
or
$ firefox http://127.0.0.1:8010


Telnet session has no help....not a very good interface.
That "CommandParser" needs a total rewrite

for example  "jicatd"

j - shows the dispatcher specific data
i - shows the current models running
c - shows current connection data
a - shows the acceptors listing
t - shows the "network configuration" table
d - disconnects

Note: This connection is "persistant" and you can do it multible times from any location

other commands

v - toggle verbose, see the log file
q - to quit the dispatcher

Note:  the Logger has to be "killed". It is in a very alpha condition
(This means I am taking the one out of $ACE_ROOT/netsvcs to use
it as a starting point.)


Build Instructions
------------------


This for  building manually on linux

To regenerate all the makefiles use the remake.sh script.
To just make a linux 

$ ./remake.rb  ## requird first time ./demake.rb will remove the makefiles

I only re-run this when I add new things, normally I just do a 

$  make clean  (use make realclean to do a complete system)
$  make


