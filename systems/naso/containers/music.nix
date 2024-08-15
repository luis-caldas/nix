{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.music}".name = networks.music;

       ###########
  ### # Navidrome # ###
       ###########

  services."${names.music}".service = {

    # Image
    image = "deluan/navidrome:latest";

    # Internal hostname
    hostname = names.music;

    # Run with default user
    user = builtins.toString config.mine.user.uid;

    # Volumes
    volumes = [
      "/data/local/containers/music:/data"
      "/data/chunk/media/music:/music:ro"
    ];

    # Networking
    networks = [ networks.music ];

  };

}