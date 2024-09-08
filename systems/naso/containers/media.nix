{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks
    (builtins.attrValues networks.media);

       ##########
  ### # Jellyfin # ###
       ##########

  services."${names.jellyfin}".service = let

    # Names of the folders that will be synced
    syncFolders = [ "anime" "cartoons" "films" "series" "eiga" ];

  in {

    # Image
    image = "lscr.io/linuxserver/jellyfin:latest";

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };

    # Volumes
    volumes = [
      "/data/local/containers/jellyfin:/config"
    ] ++
    # Extra folders mapping
    (map (eachFolder: "/data/chunk/media/${eachFolder}:/data/${eachFolder}:ro") syncFolders);

    # Networking
    networks = [ networks.media.jellyfin ];

  };

       #######
  ### # Komga # ###
       #######

  services."${names.komga}".service = {
    # Image
    image = "gotson/komga:latest";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    # User information
    user = "${builtins.toString config.mine.user.uid}";
    # Volumes
    volumes = [
      "/data/local/containers/komga:/config"
      "/data/chunk/media/manga:/data:ro"
    ];
    # Networking
    networks = [ networks.media.komga ];
  };

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
    env_file = [ "/data/local/containers/music/navi.env" ];
    # Volumes
    volumes = [
      "/data/local/containers/music/config:/data"
      "/data/chunk/media/music:/music:ro"
    ];
    # Networking
    networks = [ networks.media.navidrome ];
  };

       ##############
  ### # File Browser # ###
       ##############

  services."${names.browser}".service = {
    # Image
    image = "filebrowser/filebrowser:s6";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };
    # Volumes
    volumes = [
      "/data/chunk/media:/srv"
      "/data/local/containers/browser/database:/database"
      "/data/local/containers/browser/config:/config"
    ];
    # Networking
    networks = [ networks.media.browser ];
  };

       ##############
  ### # Simple Serve # ###
       ##############

  services."${names.shower}".service = {
    # Image
    image = "halverneus/static-file-server:latest";
    # Volumes
    volumes = [
      "/data/chunk/media:/web:ro"
    ];
    # Networking
    networks = [ networks.media.simple ];
  };


}