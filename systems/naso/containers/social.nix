{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;
  networks."${networks.social.name}".name = networks.social.name;

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
    networks = [ networks.front.name networks.social.name ];
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
    };
    env_file = [
      "/data/local/containers/matrix/database/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/database/data:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ######
  ### # Turn # ###
       ######

  services."${names.matrix.turn}".service = let

    # The ports for TURN
    turnPorts = { min = 30000; max = 30500; };

  in {
    # Image
    image = "ghcr.io/processone/eturnal:latest";
    # Name
    container_name = names.matrix.turn;
    # Depends
    depends_on = [ names.matrix.app ];
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
      ETURNAL_RELAY_MIN_PORT = turnPorts.min;
      ETURNAL_RELAY_MAX_PORT = turnPorts.max;
    };
    # Volumes
    volumes = [
      "/data/local/containers/matrix/turn/eturnal.yml:/etc/eturnal.yml:ro"
    ];
    # Networking
    ports = let
      stringPortRange = "${builtins.toString turnPorts.min}-${builtins.toString turnPorts.max}";
    in [
      "3478:3478/tcp"
      "3478:3478/udp"
      "${stringPortRange}:${stringPortRange}/udp"
    ];
    networks = [ networks.front.name ];
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
    networks = [ networks.front.name ];
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
    depends_on = [ names.matrix.app names.matrix.bridge.db.whats ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/whats/app:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ################
  ### # Bridge Discord # ###
       ################

  services."${names.matrix.bridge.disc}".service = {
    # Image
    image = "dock.mau.dev/mautrix/discord:latest";
    # Name
    container_name = names.matrix.bridge.disc;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.db.disc ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/disc/app:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       #################
  ### # Bridge Telegram # ###
       #################

  services."${names.matrix.bridge.gram}".service = {
    # Image
    image = "dock.mau.dev/mautrix/telegram:latest";
    # Name
    container_name = names.matrix.bridge.gram;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.db.gram ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/gram/app:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ##############
  ### # Bridge Slack # ###
       ##############

  services."${names.matrix.bridge.slac}".service = {
    # Image
    image = "dock.mau.dev/mautrix/slack:latest";
    # Name
    container_name = names.matrix.bridge.slac;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.db.slac ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/slac/app:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ###############
  ### # Bridge Signal # ###
       ###############

  services."${names.matrix.bridge.sig}".service = {
    # Image
    image = "dock.mau.dev/mautrix/signal:latest";
    # Name
    container_name = names.matrix.bridge.sig;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.db.sig ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/sig/app:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
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
    depends_on = [ names.matrix.app names.matrix.bridge.db.meta ];
    # Volumes
    volumes = [
      "/data/local/containers/matrix/bridge/meta/app:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

  #############################################################################
  #                                Databases                                  #
  #############################################################################

       ################
  ### # Whats Database # ###
       ################

  services."${names.matrix.bridge.db.whats}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.db.whats;
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
    networks = [ networks.social.name ];
  };

       ##################
  ### # Discord Database # ###
       ##################

  services."${names.matrix.bridge.db.disc}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.db.disc;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.disc;
      POSTGRES_DB = names.matrix.bridge.disc;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/disc/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/disc/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ###################
  ### # Telegram Database # ###
       ###################

  services."${names.matrix.bridge.db.gram}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.db.gram;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.gram;
      POSTGRES_DB = names.matrix.bridge.gram;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/gram/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/gram/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ################
  ### # Slack Database # ###
       ################

  services."${names.matrix.bridge.db.slac}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.db.slac;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.slac;
      POSTGRES_DB = names.matrix.bridge.slac;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/slac/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/slac/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       #################
  ### # Signal Database # ###
       #################

  services."${names.matrix.bridge.db.sig}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.db.sig;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.sig;
      POSTGRES_DB = names.matrix.bridge.sig;
    };
    env_file = [
      "/data/local/containers/matrix/bridge/sig/env/database.env"
    ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix/bridge/sig/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       ###############
  ### # Meta Database # ###
       ###############

  services."${names.matrix.bridge.db.meta}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix.bridge.db.meta;
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
    networks = [ networks.social.name ];
  };

}