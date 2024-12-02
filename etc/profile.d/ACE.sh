ld_pathmunge () {
        if ! echo $LD_LIBRARY_PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
           if [ "$2" = "after" ] ; then
              LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
           else
              LD_LIBRARY_PATH=$1:$LD_LIBRARY_PATH
           fi
        fi
}

export ACE_ROOT=/opt/ACE
export TAO_ROOT=$ACE_ROOT/TAO
export CIAO_ROOT=$TAO_ROOT/CIAO
export DDS_ROOT=$TAO_ROOT/DDS
export MPC_ROOT=$ACE_ROOT/MPC

if [ "$LD_LIBRARY_PATH" = "" ]; then
    export LD_LIBRARY_PATH=$ACE_ROOT/lib
  else
    ld_pathmunge $ACE_ROOT/lib
fi

ld_pathmunge $DDS_ROOT/lib after
