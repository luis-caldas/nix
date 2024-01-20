{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Database configuration
  db = rec {
    name = "cloud";
    user = name;
  };

in {

  # Networking
  networks."${networks.front.name}".external = true;
  networks."${networks.cloud.name}".name = networks.cloud.name;

       #############
  ### # Application # ###
       #############

  services."${names.cloud.app}".service = {
    # Image
    image = "nextcloud:latest";
    # Name
    container_name = names.cloud.app;
    # Dependend
    depends_on = [ names.cloud.database names.cloud.redis ];
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      # Mariadb
      MYSQL_HOST = names.cloud.database;
      MYSQL_DATABASE = db.name;
      MYSQL_USER = db.user;
      # Redis
      REDIS_HOST = names.cloud.redis;
      # Data
      NEXTCLOUD_DATA_DIR = "/data";
    };
    env_file = [ "/data/local/containers/cloud/cloud.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/cloud/application:/var/www/html"
      "/data/bunker/cloud/cloud:/data"
    ];
    # Networking
    networks = [ networks.cloud.name networks.front.name ];
  };

       ##########
  ### # Database # ###
       ##########

  services."${names.cloud.database}".service = {
    # Image
    image = "mariadb:latest";
    # Name
    container_name = names.cloud.database;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      MARIADB_DATABASE = db.name;
      MARIADB_USER = db.user;
    };
    env_file = [ "/data/local/containers/cloud/mariadb.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/cloud/mariadb:/var/lib/mysql"
    ];
    # Networking
    networks = [ networks.cloud.name ];
  };

       #######
  ### # Redis # ###
       #######

  services."${names.cloud.redis}".service = {
    # Image
    image = "redis:latest";
    # Name
    container_name = names.cloud.redis;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    # Volumes
    volumes = [
      "/data/bunker/data/containers/cloud/redis:/data"
    ];
    # Command
    command = "--save 60 1";
    # Networking
    networks = [ networks.cloud.name ];
  };

       #######
  ### # Proxy # ###
       #######

  services."${names.cloud.proxy}".service = let

    # Create the proxy configuration attr set for this container
    proxyConfiguration = pkgs.functions.container.createProxy {
      net = {
        ip = names.cloud.app;
        port = "80";
      };
      port = "9443";
      ssl = {
        key = "/data/local/containers/cloud/ssl/main.key";
        cert = "/data/local/containers/cloud/ssl/main.pem";
      };
      extraConfig = ''
          client_max_body_size 512M;
          client_body_timeout 300s;
          fastcgi_buffers 64 4K;
          location /.well-known/carddav {
              return 301 $scheme://$host:$server_port/remote.php/dav;
          }
          location /.well-known/caldav {
              return 301 $scheme://$host:$server_port/remote.php/dav;
          }
      '';
    };
  in {
    # Name
    container_name = names.cloud.proxy;
    # Networking
    networks = [ networks.cloud.name ];
  } //
  # Add the proxy configuration
  # It contains the image ports and volumes needed
  proxyConfiguration;

       ###############
  ### # NextCloud AIO # ###
       ################

  services."${names.cloud.aio}".service = let
    dataDir = "/mnt/data";
  in {
    # Image
    image = "nextcloud/all-in-one:latest";
    # Name
    container_name = names.cloud.aio;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      NEXTCLOUD_DATADIR = dataDir;
      AIO_DISABLE_BACKUP_SECTION = true;
      NEXTCLOUD_STARTUP_APPS = "deck tasks calendar contacts notes";
    };
    # Volumes
    volumes = [
      "/data/bunker/data/containers/cloud/aio:/mnt/docker-aio-config"
      "/data/bunker/cloud/aio:${dataDir}"
    ];
    # Networking
    networks = [ networks.cloud.name networks.front.name ];
  };

}