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
      /data/bunker/data/containers/list:/data
    ];
    # Networking
    networks = [
      networks.list
    ];
  };

}