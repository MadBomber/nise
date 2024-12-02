#################################################################################
#  copy my existing snmpd.conf file so we capture

%packages
net-snmp
%end 

%post
/sbin/chkconfig httpd     on  2>/dev/null
%end

%post --nochroot
cp /etc/snmp/snmpd.conf $INSTALL_ROOT/etc/snmp/snmpd.conf
%end

