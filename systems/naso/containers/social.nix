{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;
  networks."${networks.social}".name = networks.social;

       ########
  ### # Matrix # ###
       ########

  services."${names.matrix.app}".service = {
    # Image
    image = "matrixdotorg/synapse:latest";
    # Name
    container_name = names.matrix.app;
    # Depends
    depends_on = [ names.matrix.database ];
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Volumes
    volumes = [
      "/data/local/containers/matrix/main:/data"
      "/data/local/containers/matrix/bridge:/bridge"
    ];
    # Networking
    networks = [ networks.front networks.social ];
  };

       ##########
  ### # Database # ###
       ##########

  services."${names.matrix.database}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.database;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.app;
      POSTGRES_DB = names.matrix.app;
      POSTGRES_INITDB_ARGS = "--encoding=UTF-8 --lc-collate=C --lc-ctype=C";
    };
    env_file = [
      "/data/local/containers/matrix/database/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/database/data:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       #################
  ### # Admin Interface # ###
       #################

  services."${names.matrix.admin}".service = {
    # Image
    image = "awesometechnologies/synapse-admin:latest";
    # Name
    container_name = names.matrix.admin;
    # Depends
    depends_on = [ names.matrix.app ];
    # Networking
    networks = [ networks.front ];
  };
       ##############
  ### # Bridge Whats # ###
       ##############

  services."${names.matrix.bridge.whats}".service = {
    # Image
    image = "dock.mau.dev/mautrix/whatsapp:latest";
    # Name
    container_name = names.matrix.bridge.whats;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.whats ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/whats/app:/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ################
  ### # Bridge Discord # ###
       ################

  services."${names.matrix.bridge.discord}".service = {
    # Image
    image = "dock.mau.dev/mautrix/discord:latest";
    # Name
    container_name = names.matrix.bridge.discord;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.discord ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/disc/app:/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       #################
  ### # Bridge Telegram # ###
       #################

  services."${names.matrix.bridge.telegram}".service = {
    # Image
    image = "dock.mau.dev/mautrix/telegram:latest";
    # Name
    container_name = names.matrix.bridge.telegram;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.telegram ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/gram/app:/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ##############
  ### # Bridge Slack # ###
       ##############

  services."${names.matrix.bridge.slack}".service = {
    # Image
    image = "dock.mau.dev/mautrix/slack:latest";
    # Name
    container_name = names.matrix.bridge.slack;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.slack ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/slac/app:/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ###############
  ### # Bridge Signal # ###
       ###############

  services."${names.matrix.bridge.signal}".service = {
    # Image
    image = "dock.mau.dev/mautrix/signal:latest";
    # Name
    container_name = names.matrix.bridge.signal;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.signal ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/sig/app:/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       #############
  ### # Bridge Meta # ###
       #############

  services."${names.matrix.bridge.meta}".service = {
    # Image
    image = "dock.mau.dev/mautrix/meta:latest";
    # Name
    container_name = names.matrix.bridge.meta;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.meta ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/meta/app:/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

  #############################################################################
  #                                Databases                                  #
  #############################################################################

       ################
  ### # Whats Database # ###
       ################

  services."${names.matrix.bridge.database.whats}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.database.whats;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.whats;
      POSTGRES_DB = names.matrix.bridge.whats;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/whats/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/whats/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ##################
  ### # Discord Database # ###
       ##################

  services."${names.matrix.bridge.database.discord}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.database.discord;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.discord;
      POSTGRES_DB = names.matrix.bridge.discord;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/disc/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/disc/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ###################
  ### # Telegram Database # ###
       ###################

  services."${names.matrix.bridge.database.telegram}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.database.telegram;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.telegram;
      POSTGRES_DB = names.matrix.bridge.telegram;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/gram/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/gram/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ################
  ### # Slack Database # ###
       ################

  services."${names.matrix.bridge.database.slack}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.database.slack;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.slack;
      POSTGRES_DB = names.matrix.bridge.slack;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/slac/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/slac/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       #################
  ### # Signal Database # ###
       #################

  services."${names.matrix.bridge.database.signal}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.database.signal;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.signal;
      POSTGRES_DB = names.matrix.bridge.signal;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/sig/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/sig/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

       ###############
  ### # Meta Database # ###
       ###############

  services."${names.matrix.bridge.database.meta}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.database.meta;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.meta;
      POSTGRES_DB = names.matrix.bridge.meta;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/meta/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/meta/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social ];
  };

}