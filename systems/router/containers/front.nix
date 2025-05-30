{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Networks needed
  localNetworks = [
    networks.front
  ];
  externalNetworks = [
    # Portainer
    networks.manage
    # Asterisk
    networks.asterisk
    # Dashboard
    networks.dash
    # Monitor
    networks.monitor.grafana
    networks.monitor.kuma
    # VPN
    networks.vpn
  ];

in {

  # Networking
  networks =
    (pkgs.functions.container.populateNetworks localNetworks) //
    (pkgs.functions.container.generateExternalNetworks externalNetworks);

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

}