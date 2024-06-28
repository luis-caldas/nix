{ shared, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

       ################
  ### # Home Assistant # ###
       ################

  services."${names.assistant}".service = {

    # Image
    image = "ghcr.io/home-assistant/home-assistant:stable";

    # Hostname
    hostname = names.assistant;

    # Name
    container_name = names.assistant;

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };

    # Volumes
    volumes = [
      "/data/local/containers/assistant/config:/config"
    ];

    # Networking
    networks = [ networks.front ];

  };

}