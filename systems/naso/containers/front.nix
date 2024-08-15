{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.music}".external = true;
  networks."${networks.front}".name = networks.front;

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
    # Networking
    networks = [ networks.front networks.music ];
  };

       ########
  ### # Access # ###
       ########

  services."${names.front.access}".service = {
    # Image
    image = "xavierh/goaccess-for-nginxproxymanager:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      SKIP_ARCHIVED_LOGS = "False";
      DEBUG = "False";
      BASIC_AUTH = "True";
      LOG_TYPE = "NPM+R";
      HTML_REFRESH = 60;  # Every minute (between 1 ~ 60)
      KEEP_LAST = 30;
      PROCESSING_THREADS = 1;
    };
    env_file = [ "/data/local/containers/proxy/access.env" ];
    # Volumes
    volumes = [
      "/data/local/containers/proxy/application/logs:/opt/log"
    ];
    # Networking
    networks = [ networks.front ];
  };

}