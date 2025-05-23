#!/bin/sh
cat > /var/www/html/wp-config.php << EOL
<?php
define("DB_HOST", "${WORDPRESS_DB_HOST}");
define("DB_USER", "${WORDPRESS_DB_USER}");
define("DB_PASSWORD", "${WORDPRESS_DB_PASSWORD}");
define("DB_NAME", "${WORDPRESS_DB_NAME}");
define("AUTH_KEY", "put your unique phrase here");
define("SECURE_AUTH_KEY", "put your unique phrase here");
define("LOGGED_IN_KEY", "put your unique phrase here");
define("NONCE_KEY", "put your unique phrase here");
define("AUTH_SALT", "put your unique phrase here");
define("SECURE_AUTH_SALT", "put your unique phrase here");
define("LOGGED_IN_SALT", "put your unique phrase here");
define("NONCE_SALT", "put your unique phrase here");
\$table_prefix = "wp_";
define("WP_DEBUG", false);
if ( !defined("ABSPATH") ) define("ABSPATH", dirname(__FILE__) . "/");
require_once(ABSPATH . "wp-settings.php");
EOL
