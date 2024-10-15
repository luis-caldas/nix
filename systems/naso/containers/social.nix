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
    (builtins.attrValues networks.social.bridge.whats)
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
      "${paths.local.matrix}/main:/data"
      "${paths.local.bridge}:/bridge"
    ];
    # Networking
    networks = [
      networks.social.default
      networks.social.internal
      networks.social.bridge.whats.default
    ];
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
    networks = [
      networks.social.bridge.whats.default
      networks.social.bridge.whats.internal
    ];
  };

  #      ################
  # ### # Bridge Discord # ###
  #      ################

  # services."${names.matrix.bridge.discord}".service = {
  #   # Image
  #   image = "dock.mau.dev/mautrix/discord:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     UID = config.mine.user.uid;
  #     GID = config.mine.user.gid;
  #   };
  #   # Depends
  #   depends_on = [ names.matrix.app names.matrix.bridge.database.discord ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.discord}/app:/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      #################
  # ### # Bridge Telegram # ###
  #      #################

  # services."${names.matrix.bridge.telegram}".service = {
  #   # Image
  #   image = "dock.mau.dev/mautrix/telegram:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     UID = config.mine.user.uid;
  #     GID = config.mine.user.gid;
  #   };
  #   # Depends
  #   depends_on = [ names.matrix.app names.matrix.bridge.database.telegram ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.telegram}/app:/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      ##############
  # ### # Bridge Slack # ###
  #      ##############

  # services."${names.matrix.bridge.slack}".service = {
  #   # Image
  #   image = "dock.mau.dev/mautrix/slack:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     UID = config.mine.user.uid;
  #     GID = config.mine.user.gid;
  #   };
  #   # Depends
  #   depends_on = [ names.matrix.app names.matrix.bridge.database.slack ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.slack}/app:/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      ###############
  # ### # Bridge Signal # ###
  #      ###############

  # services."${names.matrix.bridge.signal}".service = {
  #   # Image
  #   image = "dock.mau.dev/mautrix/signal:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     UID = config.mine.user.uid;
  #     GID = config.mine.user.gid;
  #   };
  #   # Depends
  #   depends_on = [ names.matrix.app names.matrix.bridge.database.signal ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.signal}/app:/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      #############
  # ### # Bridge Meta # ###
  #      #############

  # services."${names.matrix.bridge.meta}".service = {
  #   # Image
  #   image = "dock.mau.dev/mautrix/meta:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     UID = config.mine.user.uid;
  #     GID = config.mine.user.gid;
  #   };
  #   # Depends
  #   depends_on = [ names.matrix.app names.matrix.bridge.database.meta ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.meta}/app:/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

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

  #      ##################
  # ### # Discord Database # ###
  #      ##################

  # services."${names.matrix.bridge.database.discord}".service = {
  #   # Image
  #   image = "postgres:16";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     POSTGRES_USER = names.matrix.bridge.discord;
  #     POSTGRES_DB = names.matrix.bridge.discord;
  #   };
  #   env_file = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.discord}/env/database.env"
  #   ];
  #   # Volumes
  #   volumes = [
  #     "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.discord}/database:/var/lib/postgresql/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      ###################
  # ### # Telegram Database # ###
  #      ###################

  # services."${names.matrix.bridge.database.telegram}".service = {
  #   # Image
  #   image = "postgres:16";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     POSTGRES_USER = names.matrix.bridge.telegram;
  #     POSTGRES_DB = names.matrix.bridge.telegram;
  #   };
  #   env_file = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.telegram}/env/database.env"
  #   ];
  #   # Volumes
  #   volumes = [
  #     "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.telegram}/database:/var/lib/postgresql/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      ################
  # ### # Slack Database # ###
  #      ################

  # services."${names.matrix.bridge.database.slack}".service = {
  #   # Image
  #   image = "postgres:16";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     POSTGRES_USER = names.matrix.bridge.slack;
  #     POSTGRES_DB = names.matrix.bridge.slack;
  #   };
  #   env_file = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.slack}/env/database.env"
  #   ];
  #   # Volumes
  #   volumes = [
  #     "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.slack}/database:/var/lib/postgresql/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      #################
  # ### # Signal Database # ###
  #      #################

  # services."${names.matrix.bridge.database.signal}".service = {
  #   # Image
  #   image = "postgres:16";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     POSTGRES_USER = names.matrix.bridge.signal;
  #     POSTGRES_DB = names.matrix.bridge.signal;
  #   };
  #   env_file = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.signal}/env/database.env"
  #   ];
  #   # Volumes
  #   volumes = [
  #     "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.signal}/database:/var/lib/postgresql/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

  #      ###############
  # ### # Meta Database # ###
  #      ###############

  # services."${names.matrix.bridge.database.meta}".service = {
  #   # Image
  #   image = "postgres:16";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     POSTGRES_USER = names.matrix.bridge.meta;
  #     POSTGRES_DB = names.matrix.bridge.meta;
  #   };
  #   env_file = [
  #     "${paths.local.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.meta}/env/database.env"
  #   ];
  #   # Volumes
  #   volumes = [
  #     "${paths.safe.bridge}/${pkgs.functions.container.getLastDash names.matrix.bridge.meta}/database:/var/lib/postgresql/data"
  #   ];
  #   # Networking
  #   networks = [ networks.social ];
  # };

}