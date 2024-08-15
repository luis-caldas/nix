{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = (pkgs.functions.container.populateNetworks [
    networks.base.time
    networks.base.hole
  ]) // {
    "${networks.base.dns}" = {
      name = networks.base.dns;
      ipam.config = [{ inherit (pkgs.networks.docker.dns.main) subnet gateway; }];
    };
  };

       #####
  ### # DNS # ###
       #####

  # Upstream DNS server
  services."${names.dns.up}" = {
    build.image = lib.mkForce pkgs.containers.dns;
    service = {
      # Networking
      networks."${networks.base.dns}".ipv4_address = pkgs.networks.docker.dns.main.ips.upstream;
    };
  };

       ########
  ### # PiHole # ###
       ########

  # PiHole
  services."${names.dns.app}".service = {

    # Image
    image = "pihole/pihole:latest";

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      DNSMASQ_LISTENING = "all";
      PIHOLE_DNS_ = pkgs.networks.docker.dns.main.ips.upstream;
    };
    env_file = [ "/data/local/containers/pihole/env/adblock.env" ];

    # Volumes
    volumes = [
      "/data/local/containers/pihole/config/etc:/etc/pihole"
      "/data/local/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
    ];

    # Networking
    ports = [
      "53:53/tcp"
      "53:53/udp"
    ];
    dns = [ "127.0.0.1" ];
    networks = [
      networks.base.dns
      networks.base.hole
    ];

  };

       ######
  ### # Time # ###
       ######

  services."${names.time}".service = {
    # Image file
    image = "simonrupf/chronyd:latest";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      NTP_SERVERS = pkgs.networks.time;
      ENABLE_NTS = "true";
    };
    # Networking
    ports = [
      "123:123/udp"
    ];
    networks = [ networks.base.time ];
  };

}