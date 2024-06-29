{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

       #########
  ### # Grafana # ###
       #########

  services."${names.monitor}".service = {

    # Image
    image = "grafana/grafana-oss:latest";

    # Hostname
    hostname = names.monitor;

    # Run with default user
    user = config.mine.user.uid;

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };

    # Volumes
    volumes = [
      "/data/local/containers/monitor/config:/var/lib/grafana"
    ];

    # Networking
    networks = [ networks.front ];

  };

       #############
  ### # Uptime Kuma # ###
       #############

  services."${names.kuma}".service = {

    # Image
    image = "louislam/uptime-kuma:latest";

    # Hostname
    hostname = names.kuma;

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };

    # Volumes
    volumes = [
      "/data/local/containers/kuma/config:/app/data"
    ];

    # Networking
    networks = [ networks.front ];

  };

}