#!/bin/tcsh

foreach hc_dir ( /ise/repos/svn/hotcopy_backup/ISE_r* )
  if (-d $hc_dir) then
    if (-e $hc_dir.tar.gz) then
      echo "$hc_dir is already compressed."
    else
      tar cvf $hc_dir.tar $hc_dir
      gzip $hc_dir.tar
    endif
  endif
end

