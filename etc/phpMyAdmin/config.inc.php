<?php

/**
 * Server(s) configuration
 */
$i = 0;
// The $cfg['Servers'] array starts with $cfg['Servers'][1].  Do not use
// $cfg['Servers'][0]. You can disable a server config entry by setting host
// to ''. If you want more than one server, just copy following section
// (including $i incrementation) serveral times. There is no need to define
// full server array, just define values you need to change.
$i++;
$cfg['Servers'][$i]['host']          = 'pcig31.lmmfc-vrsil.com'; // MySQL hostname or IP address
$cfg['Servers'][$i]['port']          = '';          // MySQL port - leave blank for default port
$cfg['Servers'][$i]['socket']        = '';          // Path to the socket - leave blank for default socket
$cfg['Servers'][$i]['connect_type']  = 'tcp';       // How to connect to MySQL server ('tcp' or 'socket')
$cfg['Servers'][$i]['extension']     = 'mysql';     // The php MySQL extension to use ('mysql' or 'mysqli')
$cfg['Servers'][$i]['compress']      = FALSE;       // Use compressed protocol for the MySQL connection
                                                    // (requires PHP >= 4.3.0)
$cfg['Servers'][$i]['controluser']   = 'pma';          // MySQL control user settings
                                                    // (this user must have read-only
$cfg['Servers'][$i]['controlpass']   = 'pma';          // access to the "mysql/user"
                                                    // and "mysql/db" tables).
                                                    // The controluser is also
                                                    // used for all relational
                                                    // features (pmadb)
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
$cfg['Servers'][$i]['user']          = '';      // MySQL user
$cfg['Servers'][$i]['password']      = '';          // MySQL password (only needed
                                                    // with 'config' auth_type)
$cfg['Servers'][$i]['only_db']       = '';          // If set to a db-name, only
                                                    // this db is displayed in left frame
                                                    // It may also be an array of db-names, where sorting order is relevant.
$cfg['Servers'][$i]['hide_db']       = '';          // Database name to be hidden from listings
$cfg['Servers'][$i]['verbose']       = '';          // Verbose name for this host - leave blank to show the hostname

$cfg['Servers'][$i]['pmadb']         = 'phpmyadmin';          // Database used for Relation, Bookmark and PDF Features
                                                    // (see scripts/create_tables.sql)
                                                    //   - leave blank for no support
                                                    //     DEFAULT: 'phpmyadmin'
$cfg['Servers'][$i]['bookmarktable'] = 'pma_bookmark';          // Bookmark table
                                                    //   - leave blank for no bookmark support
                                                    //     DEFAULT: 'pma_bookmark'
$cfg['Servers'][$i]['relation']      = 'pma_relation';          // table to describe the relation between links (see doc)
                                                    //   - leave blank for no relation-links support
                                                    //     DEFAULT: 'pma_relation'
$cfg['Servers'][$i]['table_info']    = 'pma_table_info';          // table to describe the display fields
                                                    //   - leave blank for no display fields support
                                                    //     DEFAULT: 'pma_table_info'
$cfg['Servers'][$i]['table_coords']  = 'pma_table_coords';          // table to describe the tables position for the PDF schema
                                                    //   - leave blank for no PDF schema support
                                                    //     DEFAULT: 'pma_table_coords'
$cfg['Servers'][$i]['pdf_pages']     = 'pma_pdf_pages';          // table to describe pages of relationpdf
                                                    //   - leave blank if you don't want to use this
                                                    //     DEFAULT: 'pma_pdf_pages'
$cfg['Servers'][$i]['column_info']   = 'pma_column_info';          // table to store column information
                                                    //   - leave blank for no column comments/mime types
                                                    //     DEFAULT: 'pma_column_info'
$cfg['Servers'][$i]['history']       = 'pma_history';          // table to store SQL history
                                                    //   - leave blank for no SQL query history
                                                    //     DEFAULT: 'pma_history'
$cfg['Servers'][$i]['verbose_check'] = TRUE;        // set to FALSE if you know that your pma_* tables
                                                    // are up to date. This prevents compatibility
                                                    // checks and thereby increases performance.
$cfg['Servers'][$i]['AllowRoot']     = TRUE;        // whether to allow root login
$cfg['Servers'][$i]['AllowDeny']['order']           // Host authentication order, leave blank to not use
                                     = '';
$cfg['Servers'][$i]['AllowDeny']['rules']           // Host authentication rules, leave blank for defaults
                                     = array();



//==================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'pcig23.lmmfc-vrsil.com'; // MySQL hostname or IP address
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
//==================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'pcig24.lmmfc-vrsil.com'; // MySQL hostname or IP address
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
///==================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'pcig26.lmmfc-vrsil.com'; // MySQL hostname or IP address
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
//==================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'pcig28.lmmfc-vrsil.com'; // MySQL hostname or IP address
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
///==================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'pcig32.lmmfc-vrsil.com'; // MySQL hostname or IP address
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
//===================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'LabPC104.lmmfc-vrsil.com';
$cfg['Servers'][$i]['auth_type']     = 'http';
//===================================================================================================
$i++;
$cfg['Servers'][$i]['host']          = 'LabPC105.lmmfc-vrsil.com';
$cfg['Servers'][$i]['auth_type']     = 'http';

?>
