#######################################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $<%= project_id %>_ROOT/Models/Messages
#

The Messages directory contains all the IseMessage definitions that are
specific to this project.  These messages are implemented in both C++ header
files as well as Ruby files definiting the IseMessage as a Ruby class.

There must be maintained a tight mapping between item formats so that messages
can be exchanged in a binary form between IseModels developed in C++ and Ruby.

The valid Ruby format names and their coorsponding C++ format are listed in the
table below:

Ruby Format Name      C++ Format          Description
----------------      -----------         -----------------------
:unsigned_char                            # one character
:ascii_string2                            # two characters
:ascii_string12                           # twelve characters
:ascii_string32                           # thirty-two characters
:double                                   # Double-precision float, network (big-endian) byte order
:ACE_UINT16           ACE_UINT16          # Short, network (big-endian) byte-order
:ACE_INT16            ACE_INT16           # SMELL: Short, network (big-endian) byte-order
:LITTLE_UINT16                            # Short, little-endian byte-order
:bool                 bool                # FIXME: boolean (bool) not network safe
:ACE_UINT32           ACE_UINT32          # Long, network (big-endian) byte order
:ACE_INT32            ACE_INT32           # SMELL: Long, network (big-endian) byte order
:bits_1
:bits_2
:bits_3
:bits_4
:bits_5
:bits_6
:bits_7
:bits_10
:bits_12
:bits_13
:bits_14
:bits_16
:bits_23

