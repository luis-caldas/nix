{ pkgs, lib, config, ... }:
let

  # All the wireguard info
  wireguardInfo = {

    # Subnet for Wireguard
    subnet = "10.255.254.0/24";

    # Subnet for all internal communications
    internal = "10.255.0.0/16";

    # Original Wireguard port
    original = 51820;

    # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
    # Therefore high change of not being blocked
    # Complete range is 3478 -> 3481
    # Port needs also be opened on hosting side
    container = 3478;

  };

  # Overall networking for docker
  networks = {

    wire = {
      # Base
      name = "wire";
      subnet = "172.16.50.0/24"; gateway = "172.16.50.1";
      # IPs
      ips = {
        # DNS
        dns = "172.16.50.11";
        dnsUp = "172.16.50.10";
      };
    };

  };

  # Set up container names
  names = {
    dns = "dns";
    dnsUp = "dns-up";
    wire = "wire";
  };

  # List of users for wireguard
  listUsers = let

    # Simple list that can be easily understood
    simpleList = [
      # Names will be changed for numbers starting on zero
      { home = [ "house" "router" "server" ]; }
      { lu = [ "laptop" "phone" "tablet" ]; }
      { m = [ "laptop" "phone" "extra" ]; }
      { lak = [ "laptop" "phone" "desktop" ]; }
      { extra = [ "first" "second" "third" "fourth" ]; }
    ];

    # Rename all users to
    arrayUsersDevices = map
      (eachEntry:
        builtins.concatLists (lib.attrsets.mapAttrsToList
        (eachUser: allDevices: map
          (eachDevice: "${eachUser}${pkgs.functions.capitaliseString eachDevice}")
          allDevices
        )
        eachEntry)
      )
      simpleList;

    # Join all the created lists
    interspersedUsers = lib.strings.concatStrings
      (lib.strings.intersperse "," (builtins.concatLists arrayUsersDevices));

  in interspersedUsers;

in {

  # Arion
  virtualisation.arion = {

    #######
    # VPN #
    #######

    # Main VPN containers

    projects.vpn.settings = {

      # Set up the network
      networks."${networks.wire.name}" = {
        name = networks.wire.name;
        ipam.config = [{ inherit (networks.wire) subnet gateway; }];
      };

      ### # DNS # ###

      # Upstream DNS server
      services."${names.dnsUp}" = {
        build.image = lib.mkForce pkgs.containerImages.dns;
        service = {
          # Name
          container_name = names.dnsUp;
          # Networking
          networks."${networks.wire.name}".ipv4_address = networks.wire.ips.dnsUp;
        };
      };

      ### # PiHole # ###

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

      ### # WireGuard # ###

      services."${names.wire}".service = {

        # Image file
        image = "lscr.io/linuxserver/wireguard:latest";

        # Name
        container_name = names.wire;

        # Environments
        environment = pkgs.containerFunctions.fixEnvironment {
          TZ = config.mine.system.timezone;
          PUID = config.mine.user.uid;
          GUID = config.mine.user.gid;
          INTERNAL_SUBNET = wireguardInfo.subnet;
          ALLOWEDIPS = "0.0.0.0/0,${networks.wire.ips.dns}/32,${wireguardInfo.subnet},${wireguardInfo.internal}";
          PEERS = listUsers;
          SERVERPORT = wireguardInfo.container;
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
          "${builtins.toString wireguardInfo.container}:${builtins.toString wireguardInfo.original}/udp"
        ];
        networks = [ networks.wire.name ];
        capabilities.NET_ADMIN = true;

      };

    };

  };

}