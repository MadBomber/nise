Windows instructionts:

1. Required System Environmentals  (User Space)

ACE_ROOT= _______
ISE_ROOT=C:\Users\lavender\sandbox\ise
MYSQL_ROOT=C:\Users\lavender\sandbox\mysql-5.0.67
BOOST_ROOT=C:\Users\lavender\sandbox\boost_1_36_0

2. Building boost:  bjam --tooolse=msvc-8.0 debug stage

3. Building mysql:  gotta have cmake installed!!!!

Note: You cannot use the prexisting 5.0 or 5.1, they are built with VC7.1  which we cannot link to or compile with!

(what I did!)
win\configure __NT__
win\build-vs8.bat

I have not got a complete build yet (19 to go)  before I can resurect the MASES interface

4.  get ISE and build the VS sln files (remake.rb)  

Note on rubygems...gotta get the right ones on and you have to do a "gem update --systems" prior to anything working

The gems I have on my laptop are:

C:\Users\lavender\sandbox\boost_1_36_0>gem list --local

*** LOCAL GEMS ***

actionmailer (2.1.0)
actionpack (2.1.0)
activerecord (2.1.0)
activeresource (2.1.0)
activesupport (2.1.0)
fxri (0.3.6)
fxruby (1.6.12)
highline (1.4.0)
hpricot (0.6)
log4r (1.0.5)
rails (2.1.0)
rake (0.8.1, 0.7.3)
rubygems-update (1.2.0)
sources (0.0.1)
win32-api (1.0.4)
win32-clipboard (0.4.3)
win32-dir (0.3.2)
win32-eventlog (0.4.6)
win32-file (0.5.4)
win32-file-stat (1.2.7)
win32-process (0.5.3)
win32-sapi (0.1.4)
win32-sound (0.4.1)
windows-api (0.2.0)
windows-pr (0.7.2)

5.  Get activestate's perl, must have for ACE
6.  Check out the version of ACE from our svn repository and just use the sln to build it.  That is where ACE_ROOT will point.

Jack Lavender
9/15/2008
