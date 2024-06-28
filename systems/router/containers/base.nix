{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.dns}" = {
    name = networks.dns;
    ipam.config = [{ inherit (pkgs.networks.docker.dns.main) subnet gateway; }];
  };
  networks."${networks.time}".name = networks.time;
  networks."${networks.front}".external = true;

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
      networks."${networks.dns}".ipv4_address = pkgs.networks.docker.dns.main.ips.upstream;
    };
  };

       ########
  ### # PiHole # ###
       ########

  # PiHole
  services."${names.dns.app}".service = {

    # Image
    image = "pihole/pihole:latest";

    # Name
    container_name = names.dns.app;

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
    networks = [ networks.dns networks.front ];

  };

       ######
  ### # Time # ###
       ######

  services."${names.time}".service = {
    # Image file
    image = "simonrupf/chronyd:latest";
    # Name
    container_name = names.time;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      NTP_SERVERS = "time.cloudflare.com";
      ENABLE_NTS = "true";
    };
    # Networking
    ports = [
      "123:123/udp"
    ];
    networks = [ networks.time ];
  };

}