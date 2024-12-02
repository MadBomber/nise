# fedora-live-ise.ks
#
# Maintainer(s):
# - Bruno Wolff III <bruno@wolff.to>
# - Formerly maintained by Rahul Sundaram

%include ./include/fedora-livecd-desktop.ks

# The recommended part size for DVDs is too close to use for the games spin
part / --size 10240

%packages

# no bluetooth
-bluez*
-*bluetooth*

# DNS used by Queen
#@dns-name-server
bind

# boost
boost
boost-devel

# ruby
ruby
ruby-devel
#ruby-mysql
ruby-irb
rubygems

# needed for ruby gems
libxml2-devel

# this is to satify this old codger
vim-enhanced

# Eclipse
eclipse-cdt
eclipse-jdt
eclipse-subclipse

# some other extra packages
firefox
make
wget
tkcvs

# Apache (used for wiki...only for queen)
httpd

# debugging tools
gdb
valgrind
kdbg
wireshark-gnome

%end


#################################################################################
#%post
#cat >> /etc/rc.d/init.d/livesys << EOF
#
## FEL doesn't need these and boots slowly
#/sbin/chkconfig sendmail  off 2>/dev/null
#/sbin/chkconfig nfs       off 2>/dev/null
#/sbin/chkconfig nfslock   off 2>/dev/null
#/sbin/chkconfig rpcidmapd off 2>/dev/null
#/sbin/chkconfig rpcbind   off 2>/dev/null
#
## Startup Apache
#/sbin/chkconfig httpd on 2>/dev/null
#/sbin/service httpd start
##EOF
#%end

%include ./include/mysql.ks
%include ./include/snmp.ks
%include ./include/ise-user.ks

%include ./include/queen_network.ks
%include ./include/queen_services.ks
