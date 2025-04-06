{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.tile
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

}