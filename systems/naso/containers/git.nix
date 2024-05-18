{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;
  networks."${networks.git.name}".name = networks.git.name;

       #######
  ### # Gitea # ###
       #######

  services."${names.gitea.app}".service = {

    # Image
    image = "gitea/gitea:latest";

    # Name
    container_name = names.gitea.app;

    # Depends
    depends_on = [ names.gitea.db ];

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      USER_UID = config.mine.user.uid;
      USER_GID = config.mine.user.gid;
      GITEA__database__DB_TYPE = "mysql";
      GITEA__database__HOST = "${names.gitea.db}:3306";
      GITEA__database__NAME = names.gitea.app;
      GITEA__database__USER = names.gitea.app;
      GITEA__openid__ENABLE_OPENID_SIGNIN = false;
      GITEA__service__DISABLE_REGISTRATION = true;
    };
    env_file = [ "/data/local/containers/git/database.env" ];

    # Volumes
    volumes = [
      "/data/bunker/data/containers/gitea:/data"
    ];

    # Networking
    networks = [ networks.front.name networks.git.name ];

  };

       ##########
  ### # Database # ###
       ##########

  services."${names.gitea.db}".service = {
    # Image
    image = "mariadb:latest";
    # Name
    container_name = names.gitea.db;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      MARIADB_DATABASE = names.gitea.app;
      MARIADB_USER = names.gitea.app;
    };
    env_file = [ "/data/local/containers/git/database.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/database:/var/lib/mysql"
    ];
    # Networking
    networks = [ networks.git.name ];
  };

}