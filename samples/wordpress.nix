{ config, pkgs, ... }:
# We'll start with defining some local variables
let
  # Settings used to configure the wordpress MySQL database
  mysqlHost        = "localhost";
  mysqlDb          = "wordpress";
  mysqlUser        = "wordpress";
  mysqlPassword    = "wordpress";

  mysqlDataPath    = "/data/mysql";
  wordpressUploads = "/data/uploads";
  apacheLogs       = "/data/log";

  # Our bare-bones wp-config.php file using the above settings
  wordpressConfig = pkgs.writeText "wp-config.php" ''
    <?php
    define('DB_NAME',     '${mysqlDb}');
    define('DB_USER',     '${mysqlUser}');
    define('DB_PASSWORD', '${mysqlPassword}');
    define('DB_HOST',     '${mysqlHost}');
    define('DB_CHARSET',  'utf8');
    $table_prefix  = 'wp_';
    if ( !defined('ABSPATH') )
    	define('ABSPATH', dirname(__FILE__) . '/');
    require_once(ABSPATH . 'wp-settings.php');
  '';

  # .htaccess to support pretty URLs
  htaccess = pkgs.writeText "htaccess" ''
    <IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
    </IfModule>
  '';

  # For shits and giggles, let's package the responsive theme
  responsiveTheme = pkgs.stdenv.mkDerivation {
    name = "responsive-theme";
    # Download the theme from the wordpress site
    src = pkgs.fetchurl {
      url = http://wordpress.org/themes/download/responsive.1.9.3.9.zip;
      sha256 = "0397a8nd8q384z2i4lw4a1ij835walp3b5bfdmr76mdl27vbkvmd";
    };
    # We need unzip to build this package
    buildInputs = [ pkgs.unzip ];
    # Installing simply means copying all files to the output directory
    installPhase = "mkdir -p $out; cp -R * $out/";
  };

  # The wordpress package itself
  wordpress = pkgs.stdenv.mkDerivation {
    name = "wordpress";
    # Fetch directly from the wordpress site, want to upgrade?
    # Just change the version URL and update the hash
    src = pkgs.fetchurl {
      url = http://wordpress.org/wordpress-3.7.1.tar.gz;
      sha256 = "1m2dlr54fqf5m4kgqc5hrrisrsia0r5j1r2xv1f12gmzb63swsvg";
    };
    installPhase = ''
      mkdir -p $out
      # Copy all the wordpress files we downloaded
      cp -R * $out/
      # We'll symlink the wordpress config
      ln -s ${wordpressConfig} $out/wp-config.php
      # As well as our custom .htaccess
      ln -s ${htaccess} $out/.htaccess
      # And the uploads directory
      ln -s ${wordpressUploads} $out/wp-content/uploads
      # And the responsive theme
      ln -s ${responsiveTheme} $out/wp-content/themes/responsive
      # You can add plugins the same way
    '';
  };
# This is where the body of our configuration starts
in {
  # Expose just port 80
  docker.ports = [ 80 ];

  # And let's store valuable data in a volume
  docker.volumes = [ "/data" ];

  # Apache configuration
  services.httpd = {
    enable = true;
    adminAddr = "zef@zef.me";

    # We'll set the wordpress package as our document root
    documentRoot = wordpress;

    # Let's store our logs in the volume as well
    logDir = apacheLogs;

    # And enable the PHP5 apache module
    extraModules = [ { name = "php5"; path = "${pkgs.php}/modules/libphp5.so"; } ];

    # And some extra config to make things work nicely
    extraConfig = ''
        <Directory ${wordpress}>
          DirectoryIndex index.php
          Allow from *
          Options FollowSymLinks
          AllowOverride All
        </Directory>
    '';
  };

  # Disable these when not using "localhost" as database name
  services.mysql.enable = true;
  # Let's store our data in the volume, so it'll survive restarts
  services.mysql.dataDir = mysqlDataPath;

  # This service runs evey time you start and ensures two things:
  # 1. That our uploads directory exists and is owned by Apache
  # 2. that the MySQL database exists
  supervisord.services.initApp = {
    command = pkgs.writeScript "init-wordpress.sh" ''
      #!/bin/sh

      mkdir -p ${wordpressUploads}
      chown ${config.services.httpd.user} ${wordpressUploads}

      if [ ! -d /data/mysql/${mysqlDb} ]; then
        # Wait until MySQL is up
        while [ ! -e /var/run/mysql/mysqld.pid ]; do
          sleep 1
        done
        mysql -e 'CREATE DATABASE ${mysqlDb};'
        mysql -e 'GRANT ALL ON ${mysqlDb}.* TO ${mysqlUser}@localhost IDENTIFIED BY "${mysqlPassword}";'
      fi
    '';
    # This script can exit immediately, no worries
    startsecs = 0;
  };
}