#######################################################################
###
##  File: setup_symbols.bat
##  Desc: Define the system environment varilables used by
##        the <%= project_name %> project.
##
## TODO: Rewrite this description for MS Windows command window
##
##        This file is for use with UNIX-like systems.  To establish
##        the proper environment within a shell window for the 
##        <%= project_name %> project do the following at the shell
##        command prompt:
##
##            source $<%= project_id.upcase %>_ROOT/setup_symbols
##
##        Note that $<%= project_id.upcase %>_ROOT should be setup
##        prior to sourcing setup_symbols.  One way to do this is to
##        create a file in your home directory that exports all of
##        your *_ROOT directories.  It should have an entry that looks
##        like this:
##
##            export <%= project_id.upcase %>_ROOT=<%= Dir.pwd %>
##
##
##        In the same way that $HOME/.iserc can be used by individual
##        developers to over-ride the $ISE_ROOT/setup_symbols,
##        $HOME/.<%= project_id.downcase %>rc is used to over-ride
##        the symbols defined by this file.
#

