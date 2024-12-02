CREATE TABLE `app_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_message_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `debug_flags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `dispatcher_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_peer_id` int(11) NOT NULL DEFAULT '0',
  `n_bytes` int(11) NOT NULL DEFAULT '0',
  `n_msgs` int(11) NOT NULL DEFAULT '0',
  `mean_alive` float NOT NULL DEFAULT '0',
  `stddev_alive` float NOT NULL DEFAULT '0',
  `min_time_alive` float NOT NULL DEFAULT '0',
  `max_time_alive` float NOT NULL DEFAULT '0',
  `direction` varchar(1) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `compound_index` (`run_peer_id`,`direction`),
  KEY `index_dispatcher_stats_on_run_peer_id` (`run_peer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `job_configs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `required` tinyint(1) NOT NULL DEFAULT '1',
  `job_id` int(11) NOT NULL,
  `node_id` int(11) DEFAULT '0',
  `model_id` int(11) NOT NULL,
  `model_instance` int(11) NOT NULL DEFAULT '1',
  `cmd_line_param` varchar(2048) COLLATE utf8_unicode_ci DEFAULT NULL,
  `input_file` varchar(2048) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_job_configs_on_job_id` (`job_id`),
  KEY `index_job_configs_on_model_id` (`model_id`),
  KEY `index_job_configs_on_node_id` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_by_user_id` int(11) NOT NULL,
  `updated_by_user_id` int(11) DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `default_input_dir` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `default_output_dir` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `router` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `models` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `node_id` int(11) DEFAULT NULL,
  `platform_id` int(11) DEFAULT NULL,
  `created_by_user_id` int(11) NOT NULL,
  `updated_by_user_id` int(11) DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `location` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dll` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `router` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `name_values` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `nodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fqdn` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10000 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `platforms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lib_prefix` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lib_suffix` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lib_path_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lib_path_sep` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10000 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `run_externals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) NOT NULL DEFAULT '0',
  `node_id` int(11) NOT NULL DEFAULT '0',
  `pid` int(11) NOT NULL DEFAULT '0',
  `status` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `path` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_run_externals_on_run_id` (`run_id`),
  KEY `index_run_externals_on_node_id` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `run_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) NOT NULL DEFAULT '0',
  `app_message_id` int(11) NOT NULL DEFAULT '0',
  `ref_count` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `compound_index` (`run_id`,`app_message_id`),
  KEY `index_run_messages_on_app_message_id` (`app_message_id`),
  KEY `index_run_messages_on_run_id` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `run_model_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `model_id` int(11) DEFAULT NULL,
  `instance` int(11) DEFAULT NULL,
  `cmd_line_param` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `debug_flags` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `run_models` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) NOT NULL DEFAULT '0',
  `run_peer_id` int(11) NOT NULL DEFAULT '0',
  `dll` varchar(80) COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  `instance` int(11) NOT NULL DEFAULT '0',
  `dispnodeid` int(11) NOT NULL DEFAULT '0',
  `rate` float NOT NULL DEFAULT '0',
  `model_ready` tinyint(1) NOT NULL DEFAULT '0',
  `dispatcher_ready` tinyint(1) NOT NULL DEFAULT '0',
  `status` int(11) NOT NULL DEFAULT '0',
  `execute_time` float NOT NULL DEFAULT '0',
  `extended_status` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_run_models_on_run_id` (`run_id`),
  KEY `index_run_models_on_run_peer_id` (`run_peer_id`),
  KEY `index_run_models_on_dll` (`dll`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `run_peers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `node_id` int(11) DEFAULT '0',
  `pid` int(11) NOT NULL DEFAULT '0',
  `control_port` int(11) NOT NULL DEFAULT '0',
  `status` int(11) NOT NULL DEFAULT '0',
  `peer_key` varchar(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_run_peers_on_node_id` (`node_id`),
  KEY `index_run_peers_on_peer_key` (`peer_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `run_subscribers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_message_id` int(11) NOT NULL DEFAULT '0',
  `instance` int(11) NOT NULL DEFAULT '0',
  `run_peer_id` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_run_subscribers_on_run_message_id` (`run_message_id`),
  KEY `index_run_subscribers_on_run_peer_id` (`run_peer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_id` int(11) NOT NULL,
  `run_peer_id` int(11) NOT NULL DEFAULT '0',
  `user_id` int(11) NOT NULL,
  `notification_method` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `terminated_at` datetime DEFAULT NULL,
  `status` int(11) NOT NULL,
  `debug_flags` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `guid` varchar(36) COLLATE utf8_unicode_ci NOT NULL,
  `input_dir` varchar(2048) COLLATE utf8_unicode_ci NOT NULL,
  `output_dir` varchar(2048) COLLATE utf8_unicode_ci NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_runs_on_guid` (`guid`),
  KEY `index_runs_on_job_id` (`job_id`),
  KEY `index_runs_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `status_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` int(11) DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=867572540 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin` tinyint(1) DEFAULT NULL,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1028376775 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('20110901033520');

INSERT INTO schema_migrations (version) VALUES ('20110901033602');

INSERT INTO schema_migrations (version) VALUES ('20110901033618');

INSERT INTO schema_migrations (version) VALUES ('20110901033629');

INSERT INTO schema_migrations (version) VALUES ('20110901033643');

INSERT INTO schema_migrations (version) VALUES ('20110901033653');

INSERT INTO schema_migrations (version) VALUES ('20110901033713');

INSERT INTO schema_migrations (version) VALUES ('20110901033727');

INSERT INTO schema_migrations (version) VALUES ('20110901033738');

INSERT INTO schema_migrations (version) VALUES ('20110901033749');

INSERT INTO schema_migrations (version) VALUES ('20110901033806');

INSERT INTO schema_migrations (version) VALUES ('20110901033813');

INSERT INTO schema_migrations (version) VALUES ('20110901033832');

INSERT INTO schema_migrations (version) VALUES ('20110901033839');

INSERT INTO schema_migrations (version) VALUES ('20110901033850');

INSERT INTO schema_migrations (version) VALUES ('20110901033908');

INSERT INTO schema_migrations (version) VALUES ('20110901033951');

INSERT INTO schema_migrations (version) VALUES ('201112250127');