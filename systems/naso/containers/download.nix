{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # My paths
  paths = rec {
    local = "/data/local/containers";
    base = "/data/chunk/media";
    on = builtins.listToAttrs (map
      (each: { name = each; value = "${base}/${each}"; })
      [ "downloads" ]
    );
  };

in {

  # Networking
  networks."${networks.front}".external = true;

       #########
  ### # Torrent # ###
       #########

  services."${names.download.torrent}".service = {
    # Image
    image = "lscr.io/linuxserver/qbittorrent:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
      WEBUI_PORT = 8080;
    };
    # Volumes
    volumes = [
      "${paths.local}/torrent:/config"
      "${paths.on.downloads}:/downloads"
    ];
    # Networking
    networks = [ networks.front ];
  };

       ######
  ### # Aria # ###
       ######

  services."${names.download.usenet}".service = {
    # Image
    image = "hurlenko/aria2-ariang:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
      ARIA2RPCPORT = pkgs.networks.ports.https;
    };
    # Volumes
    volumes = [
      "${paths.local}/aria:/aria2/conf"
      "${paths.on.downloads}:/aria2/data"
    ];
    # Networking
    networks = [ networks.front ];
  };

       ##########
  ### # Prowlarr # ###
       ##########

  services."${names.download.arr.fetch}".service = {

    # Image
    image = "lscr.io/linuxserver/prowlarr:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };
    # Networking
    networks = [ networks.front ];
    # Volumes
    volumes = [
      "${paths.local}/servarr/prowlarr:/config"
    ];

  };

       ########
  ### # Sonarr # ###
       ########

  services."${names.download.arr.series}".service = {
    # Image
    image = "lscr.io/linuxserver/sonarr:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };
    # Networking
    networks = [ networks.front ];
    # Volumes
    volumes = [
      "${paths.local}/servarr/sonarr:/config"
      "${paths.base}:/media"
    ];
  };

       ########
  ### # Radarr # ###
       ########

  services."${names.download.arr.films}".service = {
    # Image
    image = "lscr.io/linuxserver/radarr:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
    };
    # Networking
    networks = [ networks.front ];
    # Volumes
    volumes = [
      "${paths.local}/servarr/radarr:/config"
      "${paths.base}:/media"
    ];
  };

  #      #########
  # ### # Readarr # ###
  #      #########

  # services."${names.download.arr.books}".service = {
  #   # Image
  #   image = "lscr.io/linuxserver/readarr:develop";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     PUID = config.mine.user.uid;
  #     PGID = config.mine.user.gid;
  #   };
  #   # Networking
  #   networks = [ networks.front ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local}/servarr/readarr:/config"
  #     "${paths.base}:/media"
  #   ];
  # };

  #      ########
  # ### # Bazarr # ###
  #      ########

  # services."${names.download.arr.subtitles}".service = {
  #   # Image
  #   image = "lscr.io/linuxserver/bazarr:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     PUID = config.mine.user.uid;
  #     PGID = config.mine.user.gid;
  #   };
  #   # Networking
  #   networks = [ networks.front ];
  #   # Volumes
  #   volumes = [
  #     "${paths.local}/servarr/bazarr:/config"
  #     "${paths.base}:/media"
  #   ];
  # };

}