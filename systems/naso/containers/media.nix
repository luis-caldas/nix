{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

       ##########
  ### # Jellyfin # ###
       ##########

  services."${names.jellyfin}".service = let

    # Names of the folders that will be synced
    syncFolders = [ "anime" "cartoons" "films" "series" ];

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
    networks = [ networks.front ];

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
    networks = [ networks.front ];
  };

       ##############
  ### # File Browser # ###
       ##############

  services."${names.browser}".service = {
    # Image
    image = "filebrowser/filebrowser:s6";
    # User
    user = "${builtins.toString config.mine.user.uid}:${builtins.toString config.mine.user.gid}";
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
    networks = [ networks.front ];
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
    networks = [ networks.front ];
  };


}