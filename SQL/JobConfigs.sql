-- phpMyAdmin SQL Dump
-- version 2.9.1.1
-- http://www.phpmyadmin.net
-- 
-- Host: localhost
-- Generation Time: Jul 05, 2007 at 11:18 AM
-- Server version: 5.0.27
-- PHP Version: 5.1.6
-- 
-- Database: `Samson`
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `RegisteredJobConfig`
-- 

DROP TABLE IF EXISTS `RegisteredJobConfig`;
CREATE TABLE `RegisteredJobConfig` (
  `ID` int(5) NOT NULL,
  `DLL` varchar(80) NOT NULL,
  `Name` varchar(32) NOT NULL,
  `Count` varchar(1) NOT NULL,
  `Extra` varchar(255) default NULL,
  `External` int(11) NOT NULL default '0',
  `SortOrder` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ID`,`DLL`),
  KEY `SortOrder` (`SortOrder`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table `RegisteredJobConfig`
-- 

INSERT INTO `RegisteredJobConfig` (`ID`, `DLL`, `Name`, `Count`, `Extra`, `External`, `SortOrder`) VALUES 
(1, 'Executive', 'EXEC', '1', '-n3', 0, 2),
(1, 'Launcher', 'Lnchr', '1', '', 0, 3),
(1, 'Missile', 'Missile', '3', '', 0, 4),
(1, 'SamModelCtrl', 'Ctrlr', '1', '-m1', 0, 1),
(1, 'Sr', 'SrvRdr', '1', '', 0, 5),
(1, 'Target', 'Target', '3', '', 0, 6),
(1, 'TOC', 'TOC', '1', '', 0, 7),
(1, 'VatLogData', 'VAT', '1', '', 0, 8),
(2, 'Executive', 'EXEC', '1', '-n3', 0, 2),
(1, 'TrkRadar', 'TrkRadar', '1', NULL, 0, 9),
(2, 'Launcher', 'Lnchr', '1', '', 0, 3),
(2, 'Missile', 'Missile', '3', '', 0, 4),
(2, 'SamModelCtrl', 'Ctrlr', '1', '-m1', 0, 1),
(2, 'Sr', 'SrvRdr', '1', '', 0, 5),
(2, 'Target', 'Target', '3', '', 0, 6),
(2, 'TOC', 'TOC', '1', '', 0, 7),
(2, 'VatLogData', 'VAT', '1', '', 0, 8),
(2, 'TrkRadar', 'TrkRadar', '1', NULL, 0, 9),
(2, 'Graphic', 'Graph', '1', NULL, 0, 0),
(3, 'RamThreat', 'Target', '2', '-f "../ISE-Models/RamThreat/config"', 0, 0),
(3, 'SamModelCtrl', 'Ctrl', '1', '-m1', 0, 0),
(3, 'Graphic', 'Graph', '1', NULL, 0, 0),
(3, 'Executive', 'Exec', '1', '-n2', 0, 0),
(4, 'Executive', 'EXEC', '1', '-n1', 0, 2),
(4, 'Launcher', 'Lnchr', '1', '', 0, 3),
(4, 'Missile', 'Missile', '1', '', 0, 4),
(4, 'SamModelCtrl', 'Ctrlr', '1', '-m1', 0, 1),
(4, 'Sr', 'SrvRdr', '1', '', 0, 5),
(4, 'Target', 'Target', '1', '', 1, 6),
(4, 'TOC', 'TOC', '1', '', 0, 7),
(4, 'TrkRadar', 'TrkRadar', '1', NULL, 0, 9),
(4, 'VatLogData', 'VAT', '1', '', 0, 8),
(5, 'SamModelCtrl', 'Ctrlr', '1', '-m1', 0, 1),
(5, 'MASES_stub', 'MASES_IF', '1', NULL, 0, 9),
(5, 'Traj3DOF', 'Traj3DOF', '2', '', 1, 8),
(6, 'SamModelCtrl', 'Ctrlr', '1', '-m1', 0, 1),
(6, 'MASES_stub', 'MASES_IF', '1', NULL, 0, 9),
(6, 'Traj3DOF', 'Traj3DOF', '1', '', 1, 8),
(6, 'Sim6DOF', 'Sim6DOF', '1', '', 1, 8);


