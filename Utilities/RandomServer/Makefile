#######################################################################
###
##	File:	Makefile
##	Desc:	build instructions for RandomServer
##
#

top_srcdir	= .

CLIENT		= randomclient
SERVER		= randomserver

TARGETS		= $(CLIENT) $(SERVER)

OBJS		= RandomServ.o

COBJS		= RandomClient.o

SOBJS		= RandomServI.o \
		  RandomServer.o

SRCS		= $(OBJS:.o=.cpp) \
		  $(COBJS:.o=.cpp) \
		  $(SOBJS:.o=.cpp)

SLICE_SRCS	= RandomServ.ice

include $(top_srcdir)/config/Make.rules

ifeq ($(CXX),aCC)
#                                                                                                          
# Work-around 'quadrant warning' in aCC A.03.56
# Puts string literals in read-write memory
#
EXTRA_CPPFLAGS   := +ESnolit
endif

CPPFLAGS         := -I. $(CPPFLAGS) $(EXTRA_CPPFLAGS)


$(CLIENT): $(OBJS) $(COBJS)
	rm -f $@
	$(CXX) $(LDFLAGS) -o $@ $(OBJS) $(COBJS) $(LIBS)

$(SERVER): $(OBJS) $(SOBJS)
	rm -f $@
	$(CXX) $(LDFLAGS) -o $@ $(OBJS) $(SOBJS) $(LIBS)

include .depend
