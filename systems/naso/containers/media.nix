{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;

       ##########
  ### # Jellyfin # ###
       ##########

  services."${names.jellyfin}".service = let

    # Names of the folders that will be synced
    syncFolders = [ "anime" "cartoons" "films" "series" ];

  in {

    # Image
    image = "lscr.io/linuxserver/jellyfin:latest";

    # Name
    container_name = names.jellyfin;

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
    (map (eachFolder: "/data/storr/media/${eachFolder}:/data/${eachFolder}:ro") syncFolders);

    # Networking
    networks = [ networks.front.name ];

  };

       #######
  ### # Komga # ###
       #######

  services."${names.komga}".service = {
    # Image
    image = "gotson/komga:latest";
    # Name
    container_name = names.komga;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    # User information
    user = "${builtins.toString config.mine.user.uid}";
    # Volumes
    volumes = [
      "/data/local/containers/komga:/config"
      "/data/storr/media/manga:/data:ro"
    ];
    # Networking
    networks = [ networks.front.name ];
  };

       ##############
  ### # File Browser # ###
       ##############

  services."${names.browser}".service = {
    # Image
    image = "filebrowser/filebrowser:s6";
    # Name
    container_name = names.browser;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };
    # Volumes
    volumes = [
      "/data/storr/media:/srv"
      "/data/local/containers/browser/database:/database"
      "/data/local/containers/browser/config:/config"
    ];
    # Networking
    networks = [ networks.front.name ];
  };

       ##############
  ### # Simple Serve # ###
       ##############

  services."${names.shower}".service = {
    # Image
    image = "halverneus/static-file-server:latest";
    # Name
    container_name = names.shower;
    # Volumes
    volumes = [
      "/data/storr/media:/web:ro"
    ];
    # Networking
    networks = [ networks.front.name ];
  };


}