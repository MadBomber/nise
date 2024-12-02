#################################################################################
#
#  Prepare the ISE user (and install ACE)

%post --nochroot
#/usr/sbin/useradd -c "ISE Live" ise
#passwd -d ise > /dev/null
echo "IN post --nochroot"
df -h
env

echo "Preparing ise user"
cat >> $INSTALL_ROOT/etc/passwd  << EOF
ise:x:600:600:ISE User:/home/ise:/bin/bash
EOF

cat >> $INSTALL_ROOT/etc/group << EOF
ise:x:600:
EOF

cat >> $INSTALL_ROOT/etc/shadow << EOF
ise::14453:0:99999:7:::
EOF

mkdir  $INSTALL_ROOT/home/ise
#svn co svn://138.209.52.146/ISE/branches/edge $INSTALL_ROOT/home/ise/edge
#cp -ar /home/ise  $INSTALL_ROOT/home/ise
rsync -a /home/ise/  $INSTALL_ROOT/home/ise
chown 600  -R  $INSTALL_ROOT/home/ise
chgrp 600 -R  $INSTALL_ROOT/home/ise

cp /home/ise/edge/etc/profile.d/ACE.sh $INSTALL_ROOT/etc/profile.d/.

rsync -a --exclude '.*' --exclude '*.sln' --exclude 'debianbuild' --exclude 'Kokyu' --exclude 'apps' --exclude 'netsvcs' --exclude 'examples' --exclude 'performance-tests'  /ise/ACE-571/  $INSTALL_ROOT/opt/ACE
#cp -ar /ise/ACE-571 $INSTALL_ROOT/opt/ACE
#cp -ar /home/lavender/sandbox/ise.edge  $INSTALL_ROOT/opt/
%end

