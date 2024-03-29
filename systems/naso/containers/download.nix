{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;

       #########
  ### # Torrent # ###
       #########

  services."${names.torrent}".service = {
    # Image
    image = "lscr.io/linuxserver/qbittorrent:latest";
    # Name
    container_name = names.torrent;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
      WEBUI_PORT = 8080;
    };
    # Volumes
    volumes = [
      "/data/local/containers/torrent:/config"
      "/data/storr/media/downloads:/downloads"
    ];
    # Networking
    networks = [ networks.front.name ];
  };

       ######
  ### # Aria # ###
       ######

  services."${names.aria}".service = {
    # Image
    image = "hurlenko/aria2-ariang:latest";
    # Name
    container_name = names.aria;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      PUID = config.mine.user.uid;
      PGID = config.mine.user.gid;
      ARIA2RPCPORT = ports.https;
    };
    # Volumes
    volumes = [
      "/data/local/containers/aria:/aria2/conf"
      "/data/storr/media/downloads:/aria2/data"
    ];
    # Networking
    networks = [ networks.front.name ];
    # Service doesn't gracefully shut down, it may need tini
  };

}