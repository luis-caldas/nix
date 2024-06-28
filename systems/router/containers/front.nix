{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".name = networks.front;

       #######
  ### # Proxy # ###
       #######

  services."${names.front}".service = {
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
    networks = [ networks.front ];
  };

}