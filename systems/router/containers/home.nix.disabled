{ shared, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.home
  ];

       ################
  ### # Home Assistant # ###
       ################

  services."${names.assistant}".service = {

    # Image
    image = "ghcr.io/home-assistant/home-assistant:stable";

    # Hostname
    hostname = names.assistant;

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };

    # Volumes
    volumes = [
      "/data/local/containers/assistant/config:/config"
    ];

    # Ports
    ports = [
      "10000:10000/udp"
    ];

    # Networking
    networks = [ networks.home ];

  };

}