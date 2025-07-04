{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Networks needed
  localNetworks = [
    networks.front
  ];
  externalNetworks = [
    # Manage
    networks.manage
    # Cloud
    networks.cloud.default
    # Download
    networks.download.torrent
    networks.download.usenet
    networks.download.arr
    # Git
    networks.git.default
    # Media
    networks.media.jellyfin
    networks.media.komga
    networks.media.navidrome
    networks.media.simple
    # List
    networks.list
    # Social
    networks.social.default
    networks.social.admin
    # Track
    networks.track.default
    # Map
    networks.tile
    # Mail
    networks.mail.web
    # Vault
    networks.vault
  ];

in {

  # Networking
  networks =
    (pkgs.functions.container.populateNetworks localNetworks) //
    (pkgs.functions.container.generateExternalNetworks externalNetworks);

       #######
  ### # Proxy # ###
       #######

  services."${names.front.app}".service = {
    # Image
    image = "jc21/nginx-proxy-manager:latest";
    # Volumes
    volumes = [
      "/data/local/containers/proxy/application:/data"
      "/data/local/containers/proxy/letsencrypt:/etc/letsencrypt"
    ];
    # Networking
    ports = [
      "80:80/tcp"
      "${builtins.toString pkgs.networks.ports.https}:443/tcp"
      "81:81/tcp"
    ];
    # Health
    healthcheck = {
      # Test command
      test = [ "CMD" "/usr/bin/check-health" ];
      # Timing
      interval = "10s";
      timeout = "3s";
      retries = 5;
    };
    # Networking
    networks = localNetworks ++ externalNetworks;
  };

  #      ########
  # ### # Access # ###
  #      ########

  # services."${names.front.access}".service = {
  #   # Image
  #   image = "xavierh/goaccess-for-nginxproxymanager:latest";
  #   # Environment
  #   environment = pkgs.functions.container.fixEnvironment {
  #     TZ = config.mine.system.timezone;
  #     SKIP_ARCHIVED_LOGS = "False";
  #     DEBUG = "False";
  #     BASIC_AUTH = "True";
  #     LOG_TYPE = "NPM+R";
  #     HTML_REFRESH = 60;  # Every minute (between 1 ~ 60)
  #     KEEP_LAST = 30;
  #     PROCESSING_THREADS = 1;
  #   };
  #   env_file = [ "/data/local/containers/proxy/access.env" ];
  #   # Volumes
  #   volumes = [
  #     "/data/local/containers/proxy/application/logs:/opt/log"
  #   ];
  #   # Networking
  #   networks = [  ];
  # };

}