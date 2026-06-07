{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks
    (builtins.attrValues networks.monitor);

       #########
  ### # Grafana # ###
       #########

  services."${names.monitor}".service = {

    # Image
    image = "grafana/grafana-oss:latest";

    # Hostname
    hostname = names.monitor;

    # Run with default user
    user = builtins.toString config.mine.user.uid;

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };

    # Volumes
    volumes = [
      "/data/local/containers/monitor/config:/var/lib/grafana"
    ];

    # Networking
    networks = [ networks.monitor ];

  };

}