# $Id: Makefile 6400 2007-05-14 21:15:49Z ckarney $

TARGET = Random_UnitTest_01

all: $(TARGET)

CPPFLAGS = -I../.. 
CXXFLAGS = -g -Wall -O3 -funroll-loops -finline-functions -fomit-frame-pointer
CC = g++ -g

ifdef MTPREC64
  CPPFLAGS += -DMTPREC64
endif

ifdef USE_SFMT
  CPPFLAGS += -DUSE_SFMT
endif

HAVE_SSE2 = \
	$(shell grep "flags\b.*\bsse2\b" /proc/cpuinfo 2> /dev/null | \
	tail -1 | wc -l)

ifeq ($(HAVE_SSE2),1)
  CPPFLAGS += -DHAVE_SSE2
  CXXFLAGS += -msse2
endif

HAVE_BOOST_SERIALIZATION = \
	$(if $(wildcard /usr/lib*/libboost_serialization.*),1,0)

ifeq ($(HAVE_BOOST_SERIALIZATION),1)
  CPPFLAGS += -DHAVE_BOOST_SERIALIZATION=1
  LDLIBS = -lboost_serialization
endif

REQUIREDHEADERS = ../Random.hpp ../RandomCanonical.hpp ../Power2.hpp \
	../MT19937.hpp ../SFMT19937.hpp ../RandomSeed.hpp

OTHERHEADERS = ../NormalDistribution.hpp ../ExponentialDistribution.hpp \
	../LeadingZeros.hpp ../ExponentialProb.hpp ../RandomSelect.hpp \
	../ExactExponential.hpp ../ExactPower.hpp ../RandomNumber.hpp

### Random.o: $(REQUIREDHEADERS)

Random_UnitTest_01.o: $(REQUIREDHEADERS) ../NormalDistribution.hpp ../RandomSelect.hpp
Random_UnitTest_01: ../Random.o

#Random_UnitTest_02.0: $(REQUIREDHEADERS) ../NormalDistribution.hpp ../RandomSelect.hpp
#Random_UnitTest_02: ../Random.o


clean:
	rm -f *.o

realclean:
	rm -f *.o
	rm -f $(TARGET)

test: $(TARGET)
	./run_tests.s

rebuild:
	cp *.txt Expected_Results

