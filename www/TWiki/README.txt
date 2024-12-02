#######################################################
###
##	File:	README.txt
#

The PERL-based wiki implementation from http://twiki.org is used via the
Apache web server to provide the online integrated documentation for ISE.

This directory an its subdirectories contain ISE specific scripts, libraries
and executables.

The bin directory contains a subdirectory 'ISE' which is to be moved
into the bin directory of the active TWiki installation.  The 'ISE'
directory contains cgi scripts that enable wiki-applicaitons within the
ISEwiki to generate IseMessages and to query the status of the SunGridEngine.

The twiki.conf file goes into /etc/httpd/conf.d


The current (August 2010) version of TWiki installed is 4.2.0  It is located on
labpc108 at

	/var/www/twiki



