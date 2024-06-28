{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # My paths
  paths = rec {
    local = "/data/local/containers";
    base = "/data/chunk/media";
    on = {
      downloads = "${base}/downloads";
      anime = "${base}/anime";
      series = "${base}/series";
      films = "${base}/films";
      manga = "${base}/manga";
    };
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
    # Name
    container_name = names.download.torrent;
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
    # Name
    container_name = names.download.usenet;
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
    # Name
    container_name = names.download.arr.fetch;
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
    # Name
    container_name = names.download.arr.series;
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
      "${paths.on.series}:/series"
      "${paths.on.anime}:/anime"
      "${paths.on.downloads}:/downloads"
    ];
  };

       ########
  ### # Radarr # ###
       ########

  services."${names.download.arr.films}".service = {
    # Image
    image = "lscr.io/linuxserver/radarr:latest";
    # Name
    container_name = names.download.arr.films;
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
      "${paths.on.films}:/films"
      "${paths.on.downloads}:/downloads"
    ];
  };

       #########
  ### # Readarr # ###
       #########

  services."${names.download.arr.books}".service = {
    # Image
    image = "lscr.io/linuxserver/readarr:develop";
    # Name
    container_name = names.download.arr.books;
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
      "${paths.local}/servarr/readarr:/config"
      "${paths.on.manga}:/manga"
      "${paths.on.downloads}:/downloads"
    ];
  };

       ########
  ### # Bazarr # ###
       ########

  services."${names.download.arr.subtitles}".service = {
    # Image
    image = "lscr.io/linuxserver/bazarr:latest";
    # Name
    container_name = names.download.arr.subtitles;
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
      "${paths.local}/servarr/bazarr:/config"
      "${paths.on.films}:/films"
      "${paths.on.anime}:/anime"
      "${paths.on.series}:/series"
    ];
  };

}