{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Database configuration
  db = rec {
    name = "cloud";
    user = name;
  };

  # Main image
  imagePath = "nextcloud:latest";

  # Shared environment
  commonEnv = {
    TZ = config.mine.system.timezone;
    # Mariadb
    MYSQL_HOST = names.cloud.maria;
    MYSQL_DATABASE = db.name;
    MYSQL_USER = db.user;
    # Redis
    REDIS_HOST = names.cloud.redis;
    # Data
    NEXTCLOUD_DATA_DIR = "/data";
  };

in {

  # Networking
  networks = pkgs.functions.container.populateNetworks
    (builtins.attrValues networks.cloud);

       #############
  ### # Application # ###
       #############

  services."${names.cloud.app}".service = {
    # Image
    image = imagePath;
    # Dependend
    depends_on = [ names.cloud.maria names.cloud.redis ];
    # Environment
    environment = {
      # File upload size
      PHP_UPLOAD_LIMIT = "10G";
    }
    # Add shared environment vars
    // commonEnv;
    env_file = [ "/data/local/containers/cloud/cloud.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/cloud/application:/var/www/html"
      "/data/bunker/cloud/cloud:/data"
    ];
    # Networking
    networks = [
      networks.cloud.default
      networks.cloud.internal
    ];
  };

       ######
  ### # Cron # ###
       ######

  services."${names.cloud.cron}".service = {
    # Image
    image = imagePath;
    # Dependend
    depends_on = [ names.cloud.app ];
    # Entrypoint
    entrypoint = "/cron.sh";
    # Environment
    environment = commonEnv;
    env_file = [ "/data/local/containers/cloud/cloud.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/cloud/application:/var/www/html"
      "/data/bunker/cloud/cloud:/data"
    ];
    # Networking
    networks = [ networks.cloud.internal ];
  };

       ##########
  ### # Database # ###
       ##########

  services."${names.cloud.maria}".service = {
    # Image
    image = "mariadb:latest";
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
    networks = [ networks.cloud.internal ];
  };

       #######
  ### # Redis # ###
       #######

  services."${names.cloud.redis}".service = {
    # Image
    image = "redis:latest";
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
    networks = [ networks.cloud.internal ];
  };

}