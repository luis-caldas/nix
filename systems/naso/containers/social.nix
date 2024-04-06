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

  services."${names.matrix}".service = {
    # Image
    image = "matrixdotorg/synapse:latest";
    # Name
    container_name = names.matrix;
    # Depends
    depends_on = [ names.matrix-db ];
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

  services."${names.matrix-db}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.matrix-db;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix;
      POSTGRES_DB = names.matrix;
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

  services."${names.turn}".service = let

    # The ports for TURN
    turnPorts = { min = 30000; max = 30500; };

  in {
    # Image
    image = "ghcr.io/processone/eturnal:latest";
    # Name
    container_name = names.turn;
    # Depends
    depends_on = [ names.matrix ];
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
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

  services."${names.matrix-admin}".service = {
    # Image
    image = "awesometechnologies/synapse-admin:latest";
    # Name
    container_name = names.matrix-admin;
    # Depends
    depends_on = [ names.matrix ];
    # Networking
    networks = [ networks.front.name ];
  };

  #############################################################################
  #                                  Bridges                                  #
  #############################################################################

       ##############
  ### # Bridge Whats # ###
       ##############

  services."${names.bridge.whats}".service = {
    # Image
    image = "dock.mau.dev/mautrix/whatsapp:latest";
    # Name
    container_name = names.bridge.whats;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix names.bridge.db.whats ];
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

  services."${names.bridge.disc}".service = {
    # Image
    image = "dock.mau.dev/mautrix/discord:latest";
    # Name
    container_name = names.bridge.disc;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix names.bridge.db.disc ];
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

  services."${names.bridge.gram}".service = {
    # Image
    image = "dock.mau.dev/mautrix/telegram:latest";
    # Name
    container_name = names.bridge.gram;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix names.bridge.db.gram ];
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

  services."${names.bridge.slac}".service = {
    # Image
    image = "dock.mau.dev/mautrix/slack:latest";
    # Name
    container_name = names.bridge.slac;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix names.bridge.db.slac ];
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

  services."${names.bridge.sig}".service = {
    # Image
    image = "dock.mau.dev/mautrix/signal:latest";
    # Name
    container_name = names.bridge.sig;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix names.bridge.db.sig ];
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

  services."${names.bridge.meta}".service = {
    # Image
    image = "dock.mau.dev/mautrix/meta:latest";
    # Name
    container_name = names.bridge.meta;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = mine.system.timezone;
      UID = mine.user.uid;
      GID = mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix names.bridge.db.meta ];
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

  services."${names.bridge.db.whats}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db.whats;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.bridge.whats;
      POSTGRES_DB = names.bridge.whats;
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

  services."${names.bridge.db.disc}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db.disc;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.bridge.disc;
      POSTGRES_DB = names.bridge.disc;
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

  services."${names.bridge.db.gram}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db.gram;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.bridge.gram;
      POSTGRES_DB = names.bridge.gram;
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

  services."${names.bridge.db.slac}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db.slac;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.bridge.slac;
      POSTGRES_DB = names.bridge.slac;
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

  services."${names.bridge.db.sig}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db.sig;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.bridge.sig;
      POSTGRES_DB = names.bridge.sig;
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

  services."${names.bridge.db.meta}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db.meta;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.bridge.meta;
      POSTGRES_DB = names.bridge.meta;
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