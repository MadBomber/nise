#########################################################
#
#  create the .1 address for the queen

%post --nochroot
cat > $INSTALL_ROOT/etc/sysconfig/network-scripts/ifcfg-eth0 << FOE
DEVICE=eth0
BOOTPROTO=static
BROADCAST=192.168.7.255
IPADDR=192.168.7.1
IPV6INIT=yes
IPV6_AUTOCONF=yes
NETMASK=255.255.255.0
NETWORK=192.168.7.0
ONBOOT=yes
DNS1=192.168.7.1
NM_CONTROLLED=yes
FOE


cat > $INSTALL_ROOT/etc/sysconfig/network << FOE
IPV6_DEFAULTGW=
HOSTNAME=queen.lmmfc-ise.com
NETWORKING=yes
GATEWAY=192.168.7.1
NISDOMAIN=lmmfc-ise
NETWORKING_IPV6=yes
FOE

cat > $INSTALL_ROOT/etc/hosts  << FOE
192.168.7.1	queen.lmmfc-ise.com queen
FOE

%end 

