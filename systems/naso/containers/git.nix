{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;
  networks."${networks.git}".name = networks.git;

       #######
  ### # Gitea # ###
       #######

  services."${names.gitea.app}".service = let

    # Default SSH port
    sshPort = 222;

    # Theme
    themeName = "dark-arc";
    themeFile = "theme-${themeName}.css";
    theme = builtins.fetchurl
      "https://raw.githubusercontent.com/Jieiku/theme-${themeName}-gitea/main/${themeFile}";

  in {

    # Image
    image = "gitea/gitea:latest";

    # Name
    container_name = names.gitea.app;

    # Depends
    depends_on = [ names.gitea.database ];

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      USER_UID = config.mine.user.uid;
      USER_GID = config.mine.user.gid;
      GITEA__database__DB_TYPE = "mysql";
      GITEA__database__HOST = "${names.gitea.database}:3306";
      GITEA__database__NAME = names.gitea.app;
      GITEA__database__USER = names.gitea.app;
      GITEA____APP_NAME = pkgs.functions.capitaliseString names.gitea.app;
      GITEA__openid__ENABLE_OPENID_SIGNIN = "false";
      GITEA__service__DISABLE_REGISTRATION = "true";
      GITEA__service_0X2E_explore__REQUIRE_SIGNIN_VIEW = "true";
      GITEA__server__SSH_PORT = sshPort;
      GITEA__server__SSH_LISTEN_PORT = 22;
      GITEA__server__LANDING_PAGE = "login";
      GITEA__ui__DEFAULT_THEME = themeName;
      GITEA__ui__THEMES = "auto,gitea,arc-green,${themeName}";
    };
    env_file = [ "/data/local/containers/git/database.env" ];

    # Volumes
    volumes = [
      "/data/bunker/data/containers/git/gitea:/data"
      "${theme}:/data/gitea/public/assets/css/${themeFile}"
    ];

    # Networking
    ports = [
      "${builtins.toString sshPort}:22"
    ];
    networks = [ networks.front networks.git ];

  };

       ##########
  ### # Database # ###
       ##########

  services."${names.gitea.database}".service = {
    # Image
    image = "mariadb:latest";
    # Name
    container_name = names.gitea.database;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      MARIADB_DATABASE = names.gitea.app;
      MARIADB_USER = names.gitea.app;
    };
    env_file = [ "/data/local/containers/git/database.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/git/database:/var/lib/mysql"
    ];
    # Networking
    networks = [ networks.git ];
  };

}