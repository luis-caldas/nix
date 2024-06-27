{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the network
  networks."${networks.wire}" = {
    name = networks.wire;
    ipam.config = [{ inherit (pkgs.networks.docker.dns.vpn) subnet gateway; }];
  };

       #####
  ### # DNS # ###
       #####

  # Upstream DNS server
  services."${names.dns.up}" = {
    build.image = lib.mkForce pkgs.containers.dns;
    service = {
      # Name
      container_name = names.dns.up;
      # Networking
      networks."${networks.wire}".ipv4_address = pkgs.networks.docker.dns.vpn.ips.upstream;
    };
  };

       ########
  ### # PiHole # ###
       ########

  # Main DNS
  services."${names.dns.app}".service = {
    # Image
    image = "pihole/pihole:latest";

    # Name
    container_name = names.dns.app;

    # Depends
    depends_on = [ names.dns.up ];

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      DNSMASQ_LISTENING = "all";
      PIHOLE_DNS_ = pkgs.networks.docker.dns.vpn.ips.upstream;
    };
    env_file = [ "/data/containers/pihole/env/adblock.env" ];

    # Volumes
    volumes = [
      "/data/containers/pihole/config/etc:/etc/pihole"
      "/data/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
    ];

    # Networking
    dns = [ "127.0.0.1" ];
    networks."${networks.wire}".ipv4_address = pkgs.networks.docker.dns.vpn.ips.main;

  };

       ###########
  ### # WireGuard # ###
       ###########

  services."${names.wire}".service = {

    # Image file
    image = "lscr.io/linuxserver/wireguard:latest";

    # Name
    container_name = names.wire;

    # Environments
    environment = let
      subnet = "${pkgs.networks.vpn.network}/${builtins.toString pkgs.networks.vpn.prefix}";
    in pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      GUID = config.mine.user.gid;
      INTERNAL_SUBNET = subnet;
      ALLOWEDIPS = "0.0.0.0/0,${pkgs.networks.docker.dns.vpn.ips.main}/32,${subnet},${pkgs.networks.internal}";
      PEERS = listUsers;
      SERVERPORT = pkgs.networks.ports.open;
      PEERDNS = pkgs.networks.docker.dns.vpn.ips.main;
      PERSISTENTKEEPALIVE_PEERS = "all";
    };
    env_file = [ "/data/containers/wireguard/env/wire.env" ];

    # Volumes
    volumes = [
      "/data/containers/wireguard/config:/config"
    ];

    # Networking
    ports = [
      "${builtins.toString pkgs.networks.ports.open}:${builtins.toString pkgs.networks.ports.wireguard}/udp"
    ];
    networks = [ networks.wire ];
    capabilities.NET_ADMIN = true;

  };

}