
INC= -I . \
     -I ../../SamsonCommon \
     -I ../Messages \
     -I ../MathUtilities1p2 \
     -I /opt/ACE_wrappers

DEF= --D_REENTRANT -DACE_HAS_AIO_CALLS -D_GNU_SOURCE -DACE_HAS_EXCEPTIONS -D__ACE_INLINE__ -DPEER_BUILD_DLL

CFLAGS=-fvisibility=hidden -fvisibility-inlines-hidden -W -Wall -Wpointer-arith -O3 -g -pipe -fPIC $(DEF) $(INC)

.shobj/Graph.o: Graph.cpp
	g++ $(CFLAGS) -c Graph.cpp

libGraph.so:
	g++ -Wl,-O3 -shared -Wl,-h -Wl,libGraph.so.5.5.6 -o libGraph.so.5.5.6 .shobj/Graph.o -Wl,-E -L/opt/ACE/ace -L./ -L../../lib -L. -L/opt/ACE/lib -L../../lib -lSamsonMath -lSamsonPeer -lACE -ldl -lpthread -lrt

#g++ -fvisibility=hidden -fvisibility-inlines-hidden -W -Wall -Wpointer-arith -O3 -g -pipe    -D_REENTRANT -DACE_HAS_AIO_CALLS -D_GNU_SOURCE -I/opt/ACE -DACE_HAS_EXCEPTIONS -D__ACE_INLINE__ -I/opt/ACE -I. -I../../SamsonCommon -I../Messages -I../MathUtilities1p2 -DPEER_BUILD_DLL  -c -fPIC -o .shobj/Sr.o Sr.cpp
#g++ -Wl,-O3 -D_REENTRANT -DACE_HAS_AIO_CALLS -D_GNU_SOURCE   -I/opt/ACE -DACE_HAS_EXCEPTIONS -D__ACE_INLINE__ -I/opt/ACE -I. -I../../SamsonCommon -I../Messages -I../MathUtilities1p2 -DPEER_BUILD_DLL -shared -Wl,-h -Wl,libSr.so.5.5.6 -o libSr.so.5.5.6 .shobj/Sr.o -Wl,-E -L/opt/ACE/ace -L./ -L../../lib -L. -L/opt/ACE/lib -L../../lib -lSamsonMath -lSamsonPeer -lACE -ldl -lpthread -lrt
#rm -f libSr.so
#ln -s libSr.so.5.5.6 libSr.so
#chmod a+rx libSr.so.5.5.6
#Installing libSr.so -> ../../lib
#Installing libSr.so.5.5.6 -> ../../lib
#make[1]: Leaving directory `/home/thompson/ise/ISE/trunk/SamsonModels/SurvRadar'
#make[1]: Entering directory `/home/thompson/ise/ISE/trunk/SamsonModels/TOC'
#touch .depend.TOC
#make[1]: Leaving directory `/home/thompson/ise/ISE/trunk/SamsonModels/TOC'
#make[1]: Entering directory `/home/thompson/ise/ISE/trunk/SamsonModels/
