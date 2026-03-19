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

  services."${names.list}-old".service = {
    # Image
    image = "wingysam/christmas-community:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      # Listing
      TABLE = true;
      MARKDOWN = false;
      SINGLE_LIST = false;
      LISTS_PUBLIC = false;
      # Node
      NODE_OPTIONS = "--max-http-header-size=32768";
      # Visual
      SITE_TITLE = "Present List";
      SHORT_TITLE = "List";
      BULMASWATCH = "cyborg";
      # Networking
      PORT = 80;
      TRUST_PROXY = "10.0.0.0/8";
      UPLOAD_PFP_MAX_SIZE = "25";
      # Update
      UPDATE_CHECK = true;
    };
    # Volumes
    volumes = [
      "/data/bunker/data/containers/list/old:/data"
    ];
    # Networking
    networks = [
      networks.list
    ];
  };

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
