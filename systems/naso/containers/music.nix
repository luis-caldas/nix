{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

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
      "${paths.base}:/media/music:ro"
    ];

    # Networking
    networks = [ networks.music ];

  };

}