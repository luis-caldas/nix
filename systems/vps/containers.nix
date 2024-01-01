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
        (eachUser: allDevices: lib.lists.imap0
          (index: eachDevice: "${eachUser}${builtins.toString index}")
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

    # All the projects
    projects = {

      # Main VPN containers
      vpn.settings = let

        # Set up IPs for the containers
        ips = {
          # DNS
          dns = "172.16.50.11";
          dnsUp = "172.16.50.10";
          # WireGuard
          wire = "172.16.50.20";
        };

        # Internal docker IPs
        subnet = "172.16.50.0/24";
        gateway = "172.16.50.1";

      in {

        # Set up the network
        networks = {
          wire.ipam.config = [{ inherit subnet gateway; }];
        };

        #######
        # DNS #
        #######

        # DNS containers

        # Upstream DNS server
        services.dns-up = let currentImage = pkgs.containerImages.dns; in {
          build.image = lib.mkForce currentImage;
          service = {
            networks.wire.ipv4_address = ips.dnsUp;
          };
        };

        # PiHole
        services.dns.service = {
          image = "pihole/pihole:latest";
          depends_on = [ "dns-up" ];

          # Environment
          environment = {
            TZ = config.mine.system.timezone;
            DNSMASQ_LISTENING = "all";
            PIHOLE_DNS_ = ips.dnsUp;
          };
          env_file = [ "/data/containers/pihole/env/adblock.env" ];

          # Volumes
          volumes = [
            "/data/containers/pihole/config/etc:/etc/pihole"
            "/data/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
            # Own DNS list
            "/data/containers/pihole/config/routes.list:/etc/pihole/custom.list"
          ];

          # Networking
          dns = [ "127.0.0.1" ];
          networks.wire.ipv4_address = ips.dns;

        };

        #############
        # WireGuard #
        #############

        services.wire.service = {

          # Image file
          image = "lscr.io/linuxserver/wireguard:latest";

          # Environments
          environment = {
            TZ = config.mine.system.timezone;
            PUID = builtins.toString config.mine.user.uid;
            GUID = builtins.toString config.mine.user.gid;
            INTERNAL_SUBNET = wireguardInfo.subnet;
            ALLOWEDIPS = "0.0.0.0/0,${ips.dns}/32,${wireguardInfo.subnet},${wireguardInfo.internal}";
            PEERS = listUsers;
            SERVERPORT = builtins.toString wireguardInfo.container;
            PEERDNS = ips.dns;
            PERSISTENTKEEPALIVE_PEERS = "all";
          };
          env_file = [ "/data/containers/wireguard/env/wire.env" ];

          # Volumes
          volumes = [
            "/data/containers/wireguard/config:/config"
          ];

          # Setting up networking
          ports = [
            "${builtins.toString wireguardInfo.container}:${builtins.toString wireguardInfo.original}/udp"
          ];
          networks.wire.ipv4_address = ips.wire;
          capabilities.NET_ADMIN = true;

        };

      };

    };

  };

}