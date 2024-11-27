{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the networks
  networks = pkgs.functions.container.populateNetworks [
    networks.manage
  ];

       ###########
  ### # Portainer # ###
       ###########

  services."${names.portainer}".service = {

    # Image file
    image = "portainer/portainer-ce:lts";

    # Volumes
    volumes = [
      "/data/local/containers/portainer/data:/data"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];

    # Networking
    networks = [ networks.manage ];

  };

}