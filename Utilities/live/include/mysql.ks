#################################################################################
#
#  Setup the mysql database (TODO load Delilah)

%packages
mysql
mysql-server
mysql-libs
mysql-devel
mysql-query-browser
%end

#################################################################################
%post
cat >> /etc/rc.d/init.d/livesys << EOF

# Startup Mysql
/sbin/chkconfig mysqld on 2>/dev/null
/sbin/service mysqld start

EOF
%end

#################################################################################
%post 
cat >> /etc/rc.d/init.d/livesys-late << EOF

# Add the required users to the database with privileges, not sure about "ise"
mysql -u root -e "CREATE USER ise@localhost; GRANT ALL PRIVILEGES on *.* to ise@localhost; flush privileges;"
mysql -u root -e "CREATE USER Samson@localhost; GRANT ALL PRIVILEGES on *.* to Samson@localhost; flush privileges;"

EOF
%end

