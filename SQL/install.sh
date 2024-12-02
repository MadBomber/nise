#!/bin/sh

/usr/bin/mysqladmin -u root -h `hostname` password 'iseisnice'
/usr/bin/mysqladmin -u root -h localhost password 'iseisnice'

mysql -u root -p < $ISE_ROOT/SQL/install.sql

#build_ise_database



#cp $ISE_ROOT/etc/mysql/my.cnf ~/.my.cnf
#chmod 600 ~/.my.cnf
