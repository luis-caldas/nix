{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;

       #####

       ########
  ### # PiHole # ###
       ########

  # PiHole
  services."${names.monitor}".service = {

    # Image
    image = "pihole/pihole:latest";

    # Name
    container_name = names.monitor;

    # Environment
    environment = {
    };

    # Volumes
    volumes = [
      "/data/local/containers/monitor/config:/var/lib/grafana"
    ];

    # Networking
    networks = [ networks.front.name ];

  };

}