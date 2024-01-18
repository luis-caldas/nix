{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the network
  networks."${networks.wire.name}" = {
    name = networks.wire.name;
    ipam.config = [{ inherit (networks.wire) subnet gateway; }];
  };

       #####
  ### # DNS # ###
       #####

  # Upstream DNS server
  services."${names.dnsUp}" = {
    build.image = lib.mkForce pkgs.containers.dns;
    service = {
      # Name
      container_name = names.dnsUp;
      # Networking
      networks."${networks.wire.name}".ipv4_address = networks.wire.ips.dnsUp;
    };
  };

       ########
  ### # PiHole # ###
       ########

  # Main DNS
  services."${names.dns}".service = {
    # Image
    image = "pihole/pihole:latest";

    # Name
    container_name = names.dns;

    # Depends
    depends_on = [ names.dnsUp ];

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      DNSMASQ_LISTENING = "all";
      PIHOLE_DNS_ = networks.wire.ips.dnsUp;
    };
    env_file = [ "/data/containers/pihole/env/adblock.env" ];

    # Volumes
    volumes = [
      "/data/containers/pihole/config/etc:/etc/pihole"
      "/data/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
    ];

    # Networking
    dns = [ "127.0.0.1" ];
    networks.wire.ipv4_address = networks.wire.ips.dns;

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
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      PUID = config.mine.user.uid;
      GUID = config.mine.user.gid;
      INTERNAL_SUBNET = wireguard.subnet;
      ALLOWEDIPS = "0.0.0.0/0,${networks.wire.ips.dns}/32,${wireguard.subnet},${wireguard.internal}";
      PEERS = listUsers;
      SERVERPORT = wireguard.container;
      PEERDNS = networks.wire.ips.dns;
      PERSISTENTKEEPALIVE_PEERS = "all";
    };
    env_file = [ "/data/containers/wireguard/env/wire.env" ];

    # Volumes
    volumes = [
      "/data/containers/wireguard/config:/config"
    ];

    # Networking
    ports = [
      "${builtins.toString wireguard.container}:${builtins.toString wireguard.original}/udp"
    ];
    networks = [ networks.wire.name ];
    capabilities.NET_ADMIN = true;

  };

};