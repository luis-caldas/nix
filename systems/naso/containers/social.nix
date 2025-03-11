{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Paths
  paths = {
    local = rec {
      matrix = "/data/local/containers/matrix";
      bridge = "${matrix}/bridge";
    };
    safe = rec {
      matrix = "/data/bunker/data/containers/matrix";
      bridge = "${matrix}/bridge";
    };
  };

in {

  # Networking
  networks = pkgs.functions.container.populateNetworks (
    [
      networks.social.default
      networks.social.internal
      networks.social.admin
    ] ++
    (builtins.concatLists (lib.attrsets.mapAttrsToList
      (name: value: builtins.attrValues value)
      networks.social.bridge))
  );

       ########
  ### # Matrix # ###
       ########

  services."${names.matrix.app}".service = {
    # Image
    image = "matrixdotorg/synapse:latest";
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
      "${paths.safe.matrix}/main:/data"
      "${paths.local.bridge}:/bridge"
    ];
    # Networking
    networks = [
      networks.social.default
      networks.social.internal
    ] ++
    ( lib.attrsets.mapAttrsToList
      (name: value: value.default)
      networks.social.bridge);
  };

       ##########
  ### # Database # ###
       ##########

  services."${names.matrix.database}".service = {
    # Image
    image = "postgres:16";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.app;
      POSTGRES_DB = names.matrix.app;
      POSTGRES_INITDB_ARGS = "--encoding=UTF-8 --lc-collate=C --lc-ctype=C";
    };
    env_file = [
      "${paths.local.matrix}/database/database.env"
    ];
    # Volumes
    volumes = [
      "${paths.safe.matrix}/database/data:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.internal ];
  };

       #################
  ### # Admin Interface # ###
       #################

  services."${names.matrix.admin}".service = {
    # Image
    image = "awesometechnologies/synapse-admin:latest";
    # Depends
    depends_on = [ names.matrix.app ];
    # Networking
    networks = [ networks.social.admin ];
  };

  ############################################################################
  #                                 Bridges                                  #
  ############################################################################

       ##############
  ### # Bridge Whats # ###
       ##############

  services."${names.matrix.bridge.whats}".service = {
    # Image
    image = "dock.mau.dev/mautrix/whatsapp:latest";
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
      "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.whats}/app:/data"
    ];
    # Networking
    networks = builtins.attrValues networks.social.bridge.whats;
  };

       ##################
  ### # Bridge Messaging # ###
       ##################

  services."${names.matrix.bridge.sms}".service = {
    # Image
    image = "dock.mau.dev/mautrix/gmessages:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Depends
    depends_on = [ names.matrix.app names.matrix.bridge.database.sms ];
    # Volumes
    volumes = [
      "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.sms}/app:/data"
    ];
    # Networking
    networks = builtins.attrValues networks.social.bridge.sms;
  };

  #############################################################################
  #                                Databases                                  #
  #############################################################################

       ################
  ### # Whats Database # ###
       ################

  services."${names.matrix.bridge.database.whats}".service = {
    # Image
    image = "postgres:16";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.whats;
      POSTGRES_DB = names.matrix.bridge.whats;
    };
    env_file = [
      "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.whats}/env/database.env"
    ];
    # Volumes
    volumes = [
      "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.whats}/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.bridge.whats.internal ];
  };

       ##############
  ### # SMS Database # ###
       ##############

  services."${names.matrix.bridge.database.sms}".service = {
    # Image
    image = "postgres:16";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      POSTGRES_USER = names.matrix.bridge.sms;
      POSTGRES_DB = names.matrix.bridge.sms;
    };
    env_file = [
      "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.sms}/env/database.env"
    ];
    # Volumes
    volumes = [
      "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.sms}/database:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.bridge.sms.internal ];
  };

}