n SQL Dump
-- version 2.11.6
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 25, 2008 at 11:53 AM
-- Server version: 5.0.45
-- PHP Version: 5.2.4

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `ModelsAndServices`
--
CREATE DATABASE `ModelsAndServices` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `ModelsAndServices`;

-- --------------------------------------------------------

--
-- Table structure for table `mDBLogger_SavedPlotDetails`
--

CREATE TABLE IF NOT EXISTS `mDBLogger_SavedPlotDetails` (
  `id` int(32) NOT NULL auto_increment,
  `saved_plot_id` int(32) NOT NULL,
  `series_num` int(8) NOT NULL,
  `display_sql` varchar(5120) NOT NULL,
  `results_limit` int(32) NOT NULL,
  `fieldx` varchar(1024) NOT NULL,
  `fieldy` varchar(1024) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `saved_plot_id` (`saved_plot_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

--
-- Dumping data for table `mDBLogger_SavedPlotDetails`
--

INSERT INTO `mDBLogger_SavedPlotDetails` (`id`, `saved_plot_id`, `series_num`, `display_sql`, `results_limit`, `fieldx`, `fieldy`) VALUES
(37, 19, 1, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`TruthTargetStates` WHERE unitID_=2', 5000000, 'position__mX', 'position__mY'),
(36, 19, 0, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`TruthTargetStates` WHERE unitID_=1', 5000000, 'position__mX', 'position__mY'),
(35, 18, 0, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`TruthTargetStates`', 5000000, 'position__mX', 'position__mY'),
(29, 15, 1, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`TruthTargetStates` WHERE unitID_=1 AND time_ % 5 < .0001', 500000, 'time_', 'position__mX'),
(30, 15, 0, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`MyMissileDownlink` WHERE unitID_=1 AND time_ % 5 < 0.0001', 500000, 'time_', 'position__mX'),
(31, 16, 1, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`TruthTargetStates` WHERE unitID_=2 AND time_ % 5 < .0001', 500000, 'time_', 'position__mX'),
(32, 16, 0, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`MyMissileDownlink` WHERE unitID_=2 AND time_ % 5 < 0.0001', 500000, 'time_', 'position__mX'),
(33, 17, 1, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`TruthTargetStates` WHERE unitID_=3 AND time_ % 5 < .0001', 500000, 'time_', 'position__mX'),
(34, 17, 0, 'SELECT * FROM `%ISEPORTAL_CURRENT_UUID`.`MyMissileDownlink` WHERE unitID_=3 AND time_ % 5 < 0.0001', 500000, 'time_', 'position__mX');

-- --------------------------------------------------------

--
-- Table structure for table `mDBLogger_SavedPlots`
--

CREATE TABLE IF NOT EXISTS `mDBLogger_SavedPlots` (
  `id` int(32) NOT NULL auto_increment,
  `plot_name` varchar(1024) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

--
-- Dumping data for table `mDBLogger_SavedPlots`
--

INSERT INTO `mDBLogger_SavedPlots` (`id`, `plot_name`) VALUES
(19, 'Tutorial_ThreatAndMissile'),
(18, 'Tutorial_Threat1'),
(15, 'Missile1_Every5'),
(16, 'Missile2_Every5'),
(17, 'Missile3_Every5');
--
-- Database: `Samson`
--
CREATE DATABASE `Samson` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `Samson`;

-- --------------------------------------------------------

--
-- Table structure for table `AppMessage`
--

CREATE TABLE IF NOT EXISTS `AppMessage` (
  `ID` int(5) NOT NULL auto_increment,
  `AppMsgKey` varchar(32) NOT NULL,
  `Description` text NOT NULL,
  `sql_create` text,
  `regex_for_tostring` text,
  `sql_insert` text,
  PRIMARY KEY  (`ID`),
  KEY `AppMsgKey` (`AppMsgKey`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

--
-- Dumping data for table `AppMessage`
--

INSERT INTO `AppMessage` (`ID`, `AppMsgKey`, `Description`, `sql_create`, `regex_for_tostring`, `sql_insert`) VALUES
(1, 'InitEvent', 'InitEvent', NULL, NULL, NULL),
(2, 'StartFrame', 'Start a compute frame', NULL, NULL, NULL),
(3, 'EndFrame', 'Model has reached the end of compute frame', NULL, NULL, NULL),
(4, 'InitCase', 'InitCase', NULL, NULL, NULL),
(5, 'InitCaseComplete', 'InitCase  was Complete', NULL, NULL, NULL),
(6, 'EndCase', 'EndCase', NULL, NULL, NULL),
(7, 'EndCaseComplete', 'EndCase was Completed', NULL, NULL, NULL),
(8, 'EndRun', 'EndRun', NULL, NULL, NULL),
(9, 'EndRunComplete', 'EndRun was Complete', NULL, NULL, NULL),
(10, 'TruthTargetStates', 'Target Truth', 'CREATE TABLE IF NOT EXISTS `MessageTruthTargetStates` (`id` int(32) NOT NULL AUTO_INCREMENT, `msg_id` int(32) NOT NULL,`time` double NOT NULL, `entity` int(32) NOT NULL, `pos_x` double NOT NULL,`pos_y` double NOT NULL,`pos_z` double NOT NULL,`roll` double NOT NULL,`pitch` double NOT NULL,`yaw` double NOT NULL,PRIMARY KEY  (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;', '^[^0-9]*([0-9]*)[^0-9-]*(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*)[^0-9-]*(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*)[^0-9]*', 'INSERT INTO MessageTruthTargetStates (msg_id, time, entity, pos_x, pos_y, pos_z, roll, pitch, yaw) VALUES (%SAMSON_MSGID, %SAMSON_CURRENT_TIME, %SAMSON_REGEX_RESULT);'),
(11, 'EndEngagement', 'EndEngagement', NULL, NULL, NULL),
(12, 'SR_MeasTgttState', 'Surveillance Radar Measured Target', NULL, NULL, NULL),
(13, 'TRKRADAR_MeasPos', 'TRKRADAR Measured Position', NULL, NULL, NULL),
(14, 'TRKRADAR_ONCmd', 'TRKRADAR On data', NULL, NULL, NULL),
(15, 'LaunchRequest', 'Missile Launch data', NULL, NULL, NULL),
(16, 'TargetDestroyed', 'Target Destroyed End Engagement', NULL, NULL, NULL),
(17, 'MissileDownlink', 'Missile Downlink', 'CREATE TABLE IF NOT EXISTS `MessageMissileDownlink` (`id` int(32) NOT NULL AUTO_INCREMENT, `msg_id` int(32) NOT NULL,`time` double NOT NULL, `entity` int(32) NOT NULL, `pos_x` double NOT NULL,`pos_y` double NOT NULL,`pos_z` double NOT NULL,`roll` double NOT NULL,`pitch` double NOT NULL,`yaw` double NOT NULL,PRIMARY KEY  (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;', '^[^0-9]*([0-9]*)[^0-9-]*(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*)[^0-9-]*(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*)[^0-9]*', 'INSERT INTO `MessageMissileDownlink` (msg_id, time, entity, pos_x, pos_y, pos_z, roll, pitch, yaw) VALUES (%SAMSON_MSGID, %SAMSON_CURRENT_TIME, %SAMSON_REGEX_RESULT);'),
(18, 'MissileInitializePos', 'Missile Initialize Position', NULL, NULL, NULL),
(19, 'TrkRadar_Uplink', 'TrkRadar Uplink', NULL, NULL, NULL),
(20, 'LaunchCmd', 'Missile Launch data', NULL, NULL, NULL),
(21, 'SR_MeasTgtState', 'Surveillance Radar Measured Target', 'CREATE TABLE IF NOT EXISTS `MessageSRMeasTgtState` (`id` int(32) NOT NULL AUTO_INCREMENT, `sender_model_id` int(32) NOT NULL, `sender_unit_id` int(32) NOT NULL, `msg_id` int(32) NOT NULL,`entity` int(32) NOT NULL, `pos_x` double NOT NULL,`pos_y` double NOT NULL,`pos_z` double NOT NULL,PRIMARY KEY  (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;', '^[^0-9]*([0-9]*)[^0-9-]*(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*),(-?[0-9]*.[0-9]*)[^0-9]*', 'INSERT INTO MessageSRMeasTgtState (sender_model_id, sender_unit_id, msg_id, entity, pos_x, pos_y, pos_z) VALUES (%SAMSON_SENDER_MODELID, %SAMSON_SENDER_UNITID, %SAMSON_MSGID, %SAMSON_REGEX_RESULT);'),
(64, 'BM', 'BaseMessage', NULL, NULL, NULL),
(63, 'T3DOF_TargetStates', 'Traj3DOF Report Target States', NULL, NULL, NULL),
(62, 'T3DOF_TimeGrant', 'Traj3DOF Time Grant', NULL, NULL, NULL),
(61, 'T3DOF_RemoteSetup', 'Traj3DOF Remote Setup', NULL, NULL, NULL),
(60, 'T3DOF_LoadInput', 'Traj3DOF Load Remote Input', NULL, NULL, NULL),
(65, 'ISEReply', 'a really nice reply message', NULL, NULL, NULL),
(66, 'Shutdown', 'This model is shutting down', NULL, NULL, NULL),
(67, 'MyMissileDownlink', 'Missile Downlink', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `Dispatcher`
--

CREATE TABLE IF NOT EXISTS `Dispatcher` (
  `ID` int(5) NOT NULL auto_increment,
  ` CommandPort` int(11) NOT NULL,
  `Active` tinyint(1) NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Dispatcher`
--


-- --------------------------------------------------------

--
-- Table structure for table `DispatcherEntity`
--

CREATE TABLE IF NOT EXISTS `DispatcherEntity` (
  `ID` int(5) NOT NULL auto_increment,
  `DispatcherID` int(5) NOT NULL default '0',
  `Name` varchar(255) NOT NULL default 'localhost',
  `Host` varchar(15) NOT NULL default '192.168.0.0',
  `Port` int(5) NOT NULL default '8000',
  `ProxyRole` enum('R','T','C','B') NOT NULL default 'T',
  `ConnectionType` enum('A','P') NOT NULL default 'P',
  `MaxRetryTimeout` int(11) NOT NULL default '32',
  `Priority` int(11) NOT NULL default '1',
  `tcp_nodelay` tinyint(1) NOT NULL default '1',
  `isMaster` tinyint(1) NOT NULL default '0',
  `first_message_alert` tinyint(1) NOT NULL default '0',
  `send_buffer_size` int(11) NOT NULL default '0',
  `recv_buffer_size` int(11) NOT NULL default '0',
  `read_buffer_size` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  KEY `DispatcherID` (`DispatcherID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DispatcherEntity`
--


-- --------------------------------------------------------

--
-- Table structure for table `DispatcherEntity2Models`
--

CREATE TABLE IF NOT EXISTS `DispatcherEntity2Models` (
  `EntityID` int(5) NOT NULL,
  `ModelID` int(5) NOT NULL,
  `LastModDate` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `CreationDate` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`EntityID`,`ModelID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DispatcherEntity2Models`
--


-- --------------------------------------------------------

--
-- Table structure for table `Job`
--

CREATE TABLE IF NOT EXISTS `Job` (
  `ID` int(5) NOT NULL auto_increment,
  `Name` varchar(255) NOT NULL default '',
  `Description` text,
  `Status` int(5) NOT NULL default '0',
  `MasterID` int(5) NOT NULL default '0',
  `UUID` varchar(128) NOT NULL,
  `LastModDate` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `InputDir` varchar(2048) default NULL,
  `OutDir` varchar(512) default NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `UUID` (`UUID`),
  KEY `Name` (`Name`,`Status`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='List of Active Jobs';

--
-- Dumping data for table `Job`
--


-- --------------------------------------------------------

--
-- Table structure for table `JobProcesses`
--

CREATE TABLE IF NOT EXISTS `JobProcesses` (
  `JobID` int(5) NOT NULL,
  `DLL` varchar(80) NOT NULL,
  `Name` varchar(32) NOT NULL,
  `NumOfEntities` varchar(1) NOT NULL,
  `Extra` varchar(255) default NULL,
  `External` int(11) NOT NULL default '0',
  PRIMARY KEY  (`JobID`,`DLL`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `JobProcesses`
--


-- --------------------------------------------------------

--
-- Table structure for table `KeyValue`
--

CREATE TABLE IF NOT EXISTS `KeyValue` (
  `ID` int(11) NOT NULL auto_increment,
  `Key` varchar(32) NOT NULL,
  `Value` text NOT NULL,
  UNIQUE KEY `Key` (`Key`),
  KEY `ID` (`ID`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

--
-- Dumping data for table `KeyValue`
--

INSERT INTO `KeyValue` (`ID`, `Key`, `Value`) VALUES
(1, 'dispatcher_default', '<ConnectionRecord>\r\n<a>\r\n        <id_>1</id_>\r\n        <name_>local_apps</name_>\r\n        <host_>0.0.0.0</host_>\r\n        <port_>8001</port_>\r\n        <header_>samson</header_>\r\n        <proxy_role_>66</proxy_role_>\r\n        <connection_type_>80</connection_type_>\r\n        <max_retry_timeout_>32</max_retry_timeout_>\r\n        <priority_>9</priority_>\r\n        <tcp_nodelay>0</tcp_nodelay>\r\n        <send_buff>0</send_buff>\r\n        <recv_buff>0</recv_buff>\r\n        <read_buff>0</read_buff>\r\n</a>\r\n</ConnectionRecord>\r\n<ConnectionRecord>\r\n<a>\r\n        <id_>2</id_>\r\n        <name_>disp</name_>\r\n        <host_>0.0.0.0</host_>\r\n        <port_>8002</port_>\r\n        <header_>samson</header_>\r\n        <proxy_role_>66</proxy_role_>\r\n        <connection_type_>80</connection_type_>\r\n        <max_retry_timeout_>32</max_retry_timeout_>\r\n        <priority_>9</priority_>\r\n        <tcp_nodelay>0</tcp_nodelay>\r\n        <send_buff>0</send_buff>\r\n        <recv_buff>0</recv_buff>\r\n        <read_buff>0</read_buff>\r\n</a>\r\n</ConnectionRecord>');

-- --------------------------------------------------------

--
-- Table structure for table `MASES_Stub`
--

CREATE TABLE IF NOT EXISTS `MASES_Stub` (
  `PeerKey` varchar(32) NOT NULL,
  `UnitID` int(5) NOT NULL,
  `InputFile` varchar(255) NOT NULL,
  PRIMARY KEY  (`PeerKey`,`UnitID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `MASES_Stub`
--

INSERT INTO `MASES_Stub` (`PeerKey`, `UnitID`, `InputFile`) VALUES
('Traj3DOF', 1, 'c:\\kazz\\Source\\Traj3DOF_App\\Data\\Rocket(122mm)-1.inp'),
('Traj3DOF', 2, 'c:\\kazz\\Source\\Traj3DOF_App\\Data\\Rocket(122mm)-2.inp');

-- --------------------------------------------------------

--
-- Table structure for table `Message`
--

CREATE TABLE IF NOT EXISTS `Message` (
  `ID` int(5) NOT NULL auto_increment,
  `JobID` int(5) NOT NULL,
  `AppMsgID` int(12) NOT NULL default '0',
  `RefCount` int(5) NOT NULL default '0',
  `CreatorModelKey` varchar(32) NOT NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `RealKey` (`JobID`,`AppMsgID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='Registered Messages for a given Model';

--
-- Dumping data for table `Message`
--


-- --------------------------------------------------------

--
-- Table structure for table `Model`
--

CREATE TABLE IF NOT EXISTS `Model` (
  `ID` int(5) NOT NULL default '0',
  `JobID` int(5) NOT NULL default '0',
  `DLL` varchar(80) NOT NULL,
  `UnitID` int(5) NOT NULL default '0',
  `DispNodeID` int(5) NOT NULL default '0',
  `RunStatsID` int(5) NOT NULL,
  `Rate` float NOT NULL default '0',
  `ModelReady` int(5) NOT NULL default '0',
  `DispatcherReady` int(5) NOT NULL default '0',
  `Status` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ID`),
  KEY `JobID` (`JobID`,`DLL`,`UnitID`),
  KEY `DispNodeID` (`DispNodeID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Model`
--


-- --------------------------------------------------------

--
-- Table structure for table `Node`
--

CREATE TABLE IF NOT EXISTS `Node` (
  `ID` int(5) unsigned NOT NULL auto_increment,
  `Name` varchar(32) NOT NULL default '',
  `Description` text,
  `IPAddress` varchar(15) NOT NULL default '192.168.0.0',
  `Status` int(1) NOT NULL default '0',
  `FQDN` varchar(255) default '.samson',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `IPAddress` (`IPAddress`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 COMMENT='Contains a list of registered peers on this Samson Network';

--
-- Dumping data for table `Node`
--


-- --------------------------------------------------------

--
-- Table structure for table `Peer`
--

CREATE TABLE IF NOT EXISTS `Peer` (
  `ID` int(5) NOT NULL auto_increment,
  `NodeID` int(5) NOT NULL,
  `PID` int(5) NOT NULL,
  `PeerKey` varchar(32) NOT NULL,
  `Description` text,
  `DateCreated` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Peer`
--


-- --------------------------------------------------------

--
-- Table structure for table `RegisteredJobConfig`
--

CREATE TABLE IF NOT EXISTS `RegisteredJobConfig` (
  `ID` int(5) NOT NULL,
  `DLL` varchar(80) NOT NULL,
  `Name` varchar(32) NOT NULL,
  `NumOfEntities` varchar(1) NOT NULL,
  `Extra` varchar(255) default NULL,
  `External` int(11) NOT NULL default '0',
  `SortOrder` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ID`,`DLL`),
  KEY `SortOrder` (`SortOrder`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RegisteredJobConfig`
--

INSERT INTO `RegisteredJobConfig` (`ID`, `DLL`, `Name`, `NumOfEntities`, `Extra`, `External`, `SortOrder`) VALUES
(1, 'Executive', 'EXEC', '1', '-n3', 0, 2),
(1, 'Launcher', 'Lnchr', '1', '', 0, 3),
(1, 'Missile', 'Missile', '3', '', 0, 4),
(1, 'SamsonAppController', 'Ctrlr', '1', '-m1', 0, 1),
(1, 'Sr', 'SrvRdr', '1', '', 0, 5),
(1, 'TargetModel', 'Target', '3', '', 0, 6),
(1, 'TOC', 'TOC', '1', '', 0, 7),
(1, 'VatLogData', 'VAT', '1', '', 0, 8),
(2, 'Executive', 'EXEC', '1', '-n3', 0, 2),
(1, 'TrkRadar', 'TrkRadar', '1', NULL, 0, 9),
(2, 'Launcher', 'Lnchr', '1', '', 0, 3),
(2, 'Missile', 'Missile', '3', '', 0, 4),
(2, 'SamsonAppController', 'Ctrlr', '1', '-m1', 0, 1),
(2, 'Sr', 'SrvRdr', '1', '', 0, 5),
(2, 'TargetModel', 'Target', '3', '', 0, 6),
(2, 'TOC', 'TOC', '1', '', 0, 7),
(2, 'VatLogData', 'VAT', '1', '', 0, 8),
(2, 'TrkRadar', 'TrkRadar', '1', NULL, 0, 9),
(7, 'TutorialThreat', 'Threat', '1', '', 0, 1),
(3, 'RamThreat', 'Target', '2', '-f "../ISE-Models/RamThreat/config"', 0, 0),
(3, 'SamsonAppController', 'Ctrl', '1', '-m1', 0, 0),
(3, 'Graphic', 'Graph', '1', NULL, 0, 0),
(3, 'Executive', 'Exec', '1', '-n2', 0, 0),
(4, 'Executive', 'EXEC', '1', '-n1', 0, 2),
(4, 'Launcher', 'Lnchr', '1', '', 0, 3),
(4, 'Missile', 'Missile', '1', '', 0, 4),
(4, 'SamsonAppController', 'Ctrlr', '1', '-m1', 0, 1),
(4, 'Sr', 'SrvRdr', '1', '', 0, 5),
(4, 'TargetModel', 'Target', '1', '', 1, 6),
(4, 'TOC', 'TOC', '1', '', 0, 7),
(4, 'TrkRadar', 'TrkRadar', '1', NULL, 0, 9),
(4, 'VatLogData', 'VAT', '1', '', 0, 8),
(5, 'SamsonAppController', 'Ctrlr', '1', '-m1', 0, 1),
(5, 'MASES_stub', 'MASES_IF', '1', '', 0, 9),
(5, 'Traj3DOF', 'Traj3DOF', '2', '', 1, 8),
(6, 'SamsonAppController', 'Ctrlr', '1', '-m1', 0, 1),
(6, 'MASES_stub', 'MASES_IF', '1', NULL, 0, 9),
(6, 'Traj3DOF', 'Traj3DOF', '1', '', 1, 8),
(6, 'Sim6DOF', 'Sim6DOF', '1', '', 1, 8),
(2, 'DBLogger', 'DBLog', '1', '', 0, 10),
(7, 'TutorialMissile', 'Missile', '1', '', 0, 2),
(7, 'SamsonAppController', 'Ctrlr', '1', '-m1', 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `RegisteredModel`
--

CREATE TABLE IF NOT EXISTS `RegisteredModel` (
  `Name` varchar(32) NOT NULL,
  `DLL` varchar(80) NOT NULL,
  PRIMARY KEY  (`Name`,`DLL`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RegisteredModel`
--


-- --------------------------------------------------------

--
-- Table structure for table `RegisteredPeer`
--

CREATE TABLE IF NOT EXISTS `RegisteredPeer` (
  `DLL` varchar(80) NOT NULL,
  `Name` varchar(32) NOT NULL,
  PRIMARY KEY  (`DLL`,`Name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RegisteredPeer`
--

INSERT INTO `RegisteredPeer` (`DLL`, `Name`) VALUES
('Executive', 'EXEC'),
('Launcher', 'Lnchr'),
('Missile', 'Missile'),
('SamModelCtrl', 'Ctrlr'),
('Sr', 'SrvRdr'),
('Target', 'Target'),
('TOC', 'TOC'),
('TrkRadar', 'TrkRadar'),
('VatLogData', 'VAT');

-- --------------------------------------------------------

--
-- Table structure for table `RunStats_Dispatcher`
--

CREATE TABLE IF NOT EXISTS `RunStats_Dispatcher` (
  `ID` int(5) NOT NULL default '0',
  `Direction` char(1) NOT NULL default 'X',
  `n_bytes` int(10) NOT NULL default '0',
  `n_msgs` int(10) NOT NULL default '0',
  `mean_alive` double NOT NULL default '0',
  `stddev_alive` double NOT NULL default '0',
  `min_time_alive` double NOT NULL default '0',
  `max_time_alive` double NOT NULL default '0',
  PRIMARY KEY  (`ID`,`Direction`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunStats_Dispatcher`
--


-- --------------------------------------------------------

--
-- Table structure for table `RunStats_Master`
--

CREATE TABLE IF NOT EXISTS `RunStats_Master` (
  `ID` int(5) NOT NULL auto_increment,
  `UUID` varchar(128) NOT NULL,
  `PID` int(8) NOT NULL,
  `JobID` int(5) NOT NULL,
  `ModelID` int(5) NOT NULL,
  `NodeID` int(5) NOT NULL,
  `DispNodeID` int(6) NOT NULL,
  `UnitID` int(5) NOT NULL,
  `PeerKey` varchar(32) NOT NULL,
  PRIMARY KEY  (`ID`),
  KEY `PeerKey` (`PeerKey`),
  KEY `UnitID` (`UnitID`),
  KEY `ModelID` (`ModelID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunStats_Master`
--


-- --------------------------------------------------------

--
-- Table structure for table `Service`
--

CREATE TABLE IF NOT EXISTS `Service` (
  `ID` int(5) NOT NULL auto_increment,
  `PeeriD` int(5) NOT NULL,
  `PID` int(5) NOT NULL,
  `PPID` int(5) NOT NULL,
  `SvcKey` varchar(32) NOT NULL,
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `PeeriD` (`PeeriD`,`SvcKey`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Service`
--


-- --------------------------------------------------------

--
-- Table structure for table `ServiceRandomNumber`
--

CREATE TABLE IF NOT EXISTS `ServiceRandomNumber` (
  `ID` int(32) unsigned NOT NULL auto_increment,
  `ModelID` int(32) unsigned NOT NULL,
  `Seed` varchar(128) NOT NULL,
  `State` blob NOT NULL,
  PRIMARY KEY  (`ID`),
  KEY `ModelID` (`ModelID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ServiceRandomNumber`
--


-- --------------------------------------------------------

--
-- Table structure for table `Subscriber`
--

CREATE TABLE IF NOT EXISTS `Subscriber` (
  `MessageID` int(11) NOT NULL default '0',
  `UnitID` int(5) NOT NULL default '0',
  `ModelID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`MessageID`,`ModelID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='Message Subsciption Table';

--
-- Dumping data for table `Subscriber`
--

\\
