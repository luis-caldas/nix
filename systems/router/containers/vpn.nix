{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the networks
  networks = pkgs.functions.container.populateNetworks [
    networks.wire
  ];

       ###########
  ### # WireGuard # ###
       ###########

  services."${names.wire}" = {

    service = {

      # Image file
      image = "lscr.io/linuxserver/wireguard:latest";

      # Environments
      environment = let
        subnet = "${pkgs.networks.vpn.network}/${builtins.toString pkgs.networks.vpn.prefix}";
      in pkgs.functions.container.fixEnvironment {
        TZ = config.mine.system.timezone;
        PUID = config.mine.user.uid;
        GUID = config.mine.user.gid;
        INTERNAL_SUBNET = subnet;
        ALLOWEDIPS = "0.0.0.0/0,${pkgs.networks.docker.dns.vpn.wire.ip}/32,${subnet},${pkgs.networks.internal}";
        PEERS = listUsers;
        SERVERPORT = pkgs.networks.ports.open;
        PERSISTENTKEEPALIVE_PEERS = "all";
      };
      env_file = [ "/data/local/containers/wireguard/env/wire.env" ];

      # Volumes
      volumes = [
        "/data/local/containers/wireguard/config:/config"
      ];

      # Networking
      ports = [
        "${builtins.toString pkgs.networks.ports.open}:${builtins.toString pkgs.networks.ports.wireguard}/udp"
      ];
      networks = [ networks.wire ];
      capabilities.NET_ADMIN = true;
      sysctls = {
        "net.ipv4.conf.all.src_valid_mark" = 1;
      };

    };

    # Extra for dns name search
    out.service = {
      dns_search = ".";
    };

  };

}