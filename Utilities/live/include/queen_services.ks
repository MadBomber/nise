#############################################################
#
#  Do this in chroot mode to control the right services

%post
/sbin/chkconfig sendmail  off 2>/dev/null
/sbin/chkconfig nfs       off 2>/dev/null
/sbin/chkconfig nfslock   off 2>/dev/null
/sbin/chkconfig rpcidmapd off 2>/dev/null
/sbin/chkconfig rpcbind   off 2>/dev/null
%end

