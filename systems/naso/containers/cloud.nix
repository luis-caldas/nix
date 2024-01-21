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
      "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
      "/data/bunker/cloud/aio:${dataDir}"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
    # Networking
    networks = [ networks.cloud.name networks.front.name ];
  };

}