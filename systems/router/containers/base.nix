{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.dns.name}" = {
    name = networks.dns.name;
    ipam.config = [{ inherit (networks.dns) subnet gateway; }];
  };
  networks."${networks.time.name}".name = networks.time.name;
  networks."${networks.front.name}".external = true;

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
      networks."${networks.dns.name}".ipv4_address = networks.dns.ips.dnsUp;
    };
  };

       ########
  ### # PiHole # ###
       ########

  # PiHole
  services."${names.dns}".service = {

    # Image
    image = "pihole/pihole:latest";

    # Name
    container_name = names.dns;

    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      DNSMASQ_LISTENING = "all";
      PIHOLE_DNS_ = networks.dns.ips.dnsUp;
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
    networks = [ networks.dns.name networks.front.name ];

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
    networks = [ networks.time.name ];
  };

}