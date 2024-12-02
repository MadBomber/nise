--
-- Create Delilah database and Samson user.
--
-- Command: mysql -u root -p < install.sql
--

-- if the Delilah database exists, drop it then create it fresh

DROP DATABASE if exists Delilah ;
CREATE DATABASE Delilah CHARACTER SET utf8 COLLATE utf8_general_ci  ;

DROP DATABASE if exists NewDelilah ;
CREATE DATABASE NewDelilah CHARACTER SET utf8 COLLATE utf8_general_ci  ;

-- Setup access privileges for all users.  If user does not exist it will be created

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'frank.local' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;

GRANT ALL PRIVILEGES ON *.* TO 'ise'@'%' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'ise'@'localhost' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'ise'@'frank.local' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;

GRANT ALL PRIVILEGES ON *.* TO 'Samson'@'%' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'Samson'@'localhost' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'Samson'@'frank.local' IDENTIFIED BY 'iseisnice' WITH GRANT OPTION;

GRANT ALL PRIVILEGES ON Delilah.* TO 'Samson'@'%' IDENTIFIED BY 'Samson' ;
GRANT ALL PRIVILEGES ON Delilah.* TO 'Samson'@'localhost' IDENTIFIED BY 'Samson' ;
GRANT ALL PRIVILEGES ON Delilah.* TO 'Samson'@'frank.local' IDENTIFIED BY 'Samson' ;

GRANT ALL PRIVILEGES ON NewDelilah.* TO 'Samson'@'%' IDENTIFIED BY 'Samson' ;
GRANT ALL PRIVILEGES ON NewDelilah.* TO 'Samson'@'localhost' IDENTIFIED BY 'Samson' ;
GRANT ALL PRIVILEGES ON NewDelilah.* TO 'Samson'@'frank.local' IDENTIFIED BY 'Samson' ;


FLUSH PRIVILEGES;

