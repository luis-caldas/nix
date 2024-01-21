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
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Volumes
    volumes = [
      "/data/bunker/data/containers/matrix:/data"
    ];
    # Networking
    networks = [ networks.front.name networks.social.name ];
  };

       ##############
  ### # Bridge Whats # ###
       ##############

  services."${names.bridge.whats}".service = {
    # Image
    image = "dock.mau.dev/mautrix/whatsapp:latest";
    # Name
    container_name = names.bridge.whats;
    # Depends
    depends_on = [ names.matrix names.bridge.db ];
    # Volumes
    volumes = [
      "/data/local/containers/bridge/whats:/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

       #################
  ### # Bridge Database # ###
       #################

  services."${names.bridge.db}".service = {
    # Image
    image = "postgres:latest";
    # Name
    container_name = names.bridge.db;
    # Environment
    env_file = [ "/data/local/containers/bridge/database/env/db.env" ];
    # Volumes
    volumes = [
      "/data/local/containers/bridge/database/data:/var/lib/postgresql/data"
    ];
    # Networking
    networks = [ networks.social.name ];
  };

}