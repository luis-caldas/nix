{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.games
  ];

       ###########
  ### # Emulating # ###
       ###########

  services."${names.emulator}".service = {

    # Image
    image = "lscr.io/linuxserver/emulatorjs:latest";

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };

    # Volumes
    volumes = [
      # Data
      "/data/local/containers/emulator/config:/config"
      "/data/local/containers/emulator/data:/data"
      # Games
      "/data/chunk/media/games/roms:/roms:ro"
    ];

    networks = [ networks.games ];

  };

}