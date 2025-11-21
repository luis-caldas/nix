{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.tile
    networks.fmd
  ];

       ######
  ### # Tile # ###
       ######

  services."${names.tile}".service = {

    # Image
    image = "ghcr.io/luis-caldas/mapper:latest";

    # Internal hostname
    hostname = names.tile;

    # Networking
    networks = [
      networks.tile
    ];

  };

       ################
  ### # Find My Device # ###
       ################

  services."${names.fmd}".service = {

    # Image
    image = "registry.gitlab.com/fmd-foss/fmd-server:v0.12.0";

    # Internal hostname
    hostname = names.fmd;

    # Networking
    networks = [
      networks.fmd
    ];

    # Volumes
    volumes = [
      "/data/local/containers/fmd/config:/etc/fmd-server/"
      "/data/local/containers/fmd/database:/var/lib/fmd-server/db/"
    ];

  };


}