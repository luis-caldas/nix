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
      "/data/local/containers/proxy:/data"
    ];
    # Networking
    ports = [
      "80:80/tcp"
      "443:443/tcp"
      "81:81/tcp"
    ];
    # Networking
    networks = [ networks.front.name ];
  };

}