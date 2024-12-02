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
\\
