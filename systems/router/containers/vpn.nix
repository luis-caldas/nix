{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the networks
  networks = pkgs.functions.container.populateNetworks [
    networks.vpn
  ];

       ###########
  ### # Wireguard # ###
       ###########

  services."${names.vpn}".service = {

    # Image file
    image = "ghcr.io/wg-easy/wg-easy:latest";

    # Environments
    environment = pkgs.functions.container.fixEnvironment {
      LANG = "en";
      PORT = 80;  # WebUI Port
      WG_PORT = builtins.toString pkgs.networks.ports.open;  # VPN Port
      WG_CONFIG_PORT = builtins.toString pkgs.networks.ports.open;
      WG_PERSISTENT_KEEPALIVE = 25;
      WG_DEFAULT_ADDRESS = "10.200.0.x";
      WG_DEFAULT_DNS = builtins.head pkgs.networks.dns;
      UI_TRAFFIC_STATS = true;
      UI_CHART_TYPE = 1;
    };
    env_file = [ "/data/local/containers/wireguard/env/wire.env" ];

    # Volumes
    volumes = [
      "/data/local/containers/wireguard/config:/etc/wireguard"
    ];

    # Networking
    ports = [
      "${builtins.toString pkgs.networks.ports.open}:${builtins.toString pkgs.networks.ports.open}/udp"
    ];
    networks = [ networks.vpn ];
    capabilities = {
      NET_ADMIN = true;
      SYS_MODULE = true;
    };
    sysctls = {
      "net.ipv4.conf.all.src_valid_mark" = 1;
      "net.ipv4.ip_forward" = 1;
    };

  };

}