{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;
  networks."${networks.search.name}".name = networks.search.name;

       #########
  ### # SearXNG # ###
       #########

  services."${names.search.app}".service = {
    # Image
    image = "searxng/searxng:latest";
    # Name
    container_name = names.search.app;
    # Depends
    depends_on = [ names.search.redis ];
    # Environment
    env_file = [ "/data/local/containers/search/searx.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/search/application:/etc/searxng:rw"
    ];
    # Capabilities
    capabilities = {
      ALL = false;
      CHOWN = true;
      SETUID = true;
      SETGID = true;
    };
    # Networking
    networks = [ networks.search.name networks.front.name ];
  };

       #######
  ### # Redis # ###
       #######

  services."${names.search.redis}".service = {
    # Image
    image = "redis:latest";
    # Name
    container_name = names.search.redis;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    # Volumes
    volumes = [
      "/data/bunker/data/containers/search/redis:/data"
    ];
    # Command
    command = "--save 30 1";
    # Networking
    networks = [ networks.search.name ];
  };

}