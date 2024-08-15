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

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      # Visual
      ND_DEFAULTTHEME = "Spotify-ish";
      ND_UILOGINBACKGROUNDURL = "data:image/webp;base64,UklGRhoAAABXRUJQVlA4TA4AAAAvY8AYAAcQEf0PRET/Aw==";
    };

    # Volumes
    volumes = [
      "/data/local/containers/music:/data"
      "/data/chunk/media/music:/music:ro"
    ];

    # Networking
    networks = [ networks.music ];

  };

}