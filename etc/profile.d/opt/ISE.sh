ld_pathmunge () {
        if ! echo $LD_LIBRARY_PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
           if [ "$2" = "after" ] ; then
              LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
           else
              LD_LIBRARY_PATH=$1:$LD_LIBRARY_PATH
           fi
        fi
}

export ISE_ROOT=`pwd`
export PATH=$PATH:$ISE_ROOT/bin

if [ "$LD_LIBRARY_PATH" = "" ]; then
    export LD_LIBRARY_PATH=$ISE_ROOT/lib
  else
    ld_pathmunge $ISE_ROOT/lib
fi

