{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".name = networks.front.name;

       #######
  ### # Proxy # ###
       #######

  services."${names.front}".service = {
    # Image
    image = "jc21/nginx-proxy-manager:latest";
    # Name
    container_name = names.front;
    # Volumes
    volumes = [
      "/data/local/containers/proxy/application:/data"
      "/data/local/containers/proxy/letsencrypt:/etc/letsencrypt"
    ];
    # Networking
    ports = [
      "80:80/tcp"
      "${ports.https}:443/tcp"
      "81:81/tcp"
    ];
    # Networking
    networks = [ networks.front.name ];
  };

       ########
  ### # Access # ###
       ########

  services."${names.access}".service = {
    # Image
    image = "xavierh/goaccess-for-nginxproxymanager:latest";
    # Name
    container_name = names.access;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      SKIP_ARCHIVED_LOGS = "False";
      DEBUG = "False";
      BASIC_AUTH = "True";
      LOG_TYPE = "NPM+R";
      HTML_REFRESH = 5;
      KEEP_LAST = 30;
      PROCESSING_THREADS = 1;
    };
    env_file = [ "/data/local/containers/proxy/application/access.env" ];
    # Volumes
    volumes = [
      "/data/local/containers/proxy/application/logs:/opt/log"
    ];
    # Networking
    networks = [ networks.front.name ];
  };

}