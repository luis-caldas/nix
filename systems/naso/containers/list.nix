{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;
{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.list
  ];

       ######
  ### # List # ###
       ######

  services."${names.list}".service = {
    # Image
    image = "ghcr.io/cmintey/wishlist:latest";

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TOKEN_TIME = "72";  # Hours
      DEFAULT_CURRENCY = "EUR";
      MAX_IMAGE_SIZE = "26214400";  # 25 MiB
    };
    env_file = [ "/data/local/containers/list/list.env" ];

    # Volumes
    volumes = [
      "/data/bunker/data/containers/list/uploads:/usr/src/app/uploads"
      "/data/bunker/data/containers/list/data:/usr/src/app/data"
    ];

    # Networking
    networks = [
      networks.list
    ];
  };

}
