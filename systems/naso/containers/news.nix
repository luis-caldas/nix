{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the networks
  networks = pkgs.functions.container.populateNetworks [
    networks.news
  ];

       ##########
  ### # FreshRSS # ###
       ##########

  services."${names.fresh}".service = {

    # Image
    image = "lscr.io/linuxserver/freshrss:latest";

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };

    # Volumes
    volumes = [
      "/data/local/containers/freshrss:/config"
    ];

    # Networking
    networks = [ networks.news ];

  };

}