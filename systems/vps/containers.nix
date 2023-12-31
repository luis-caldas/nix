{ pkgs, lib, config, ... }:
let

    # Docker configuration
    containers = rec {

      # Name of the internal interface
      name = "internal";
      interface = "int0";

      # Internal docker IPs
      range = "172.16.50.0/24";

      # IPs for the containers
      each = {
        # DNS
        dns = "172.16.50.11";
        dnsUp = "172.16.50.10";
        # WireGuard
        wire = "172.16.50.20";
      };

      # Wireguard

      # Subnet for Wireguard
      subnet = "10.255.254.0/24";

      # Subnet for all internal communications
      remote = "10.255.255.1/24";

      # Original Wireguard port
      original = 51820;

      # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
      # Therefore high change of not being blocked
      # Complete range is 3478 -> 3481
      # Port needs also be opened on hosting side
      container = 3478;

    };

in {

  # Set up the networking creation service
  systemd.services = pkgs.containerFunctions.addNetworks {
    "${containers.name}" = { range = containers.range; interface = containers.interface; };
  };


  # All containers
  virtualisation.oci-containers.containers = {

    #############
    # WireGuard #
    #############

    wireguard = let
      allUsers = [
        # Names will be changed for numbers starting on zero
        { home = [ "house" "router" "server" ]; }
        { lu = [ "laptop" "phone" "tablet" ]; }
        { m = [ "laptop" "phone" "extra" ]; }
        { lak = [ "laptop" "phone" "desktop" ]; }
        { extra = [ "first" "second" "third" "fourth" ]; }
      ];
      allPeers = let
        arrayUsersDevices = map
          (eachEntry:
            builtins.concatLists (lib.attrsets.mapAttrsToList
            (eachUser: allDevices: lib.lists.imap0
              (index: eachDevice: "${eachUser}${builtins.toString index}")
              allDevices
            )
            eachEntry)
          )
          allUsers;
        usersDevicesList = builtins.concatLists arrayUsersDevices;
        interspersedList = lib.strings.intersperse "," usersDevicesList;
      in lib.strings.concatStrings interspersedList;
    in {
      image = "lscr.io/linuxserver/wireguard:latest";
      environment = {
        TZ = config.mine.system.timezone;
        PUID = builtins.toString config.mine.user.uid;
        GUID = builtins.toString config.mine.user.gid;
        INTERNAL_SUBNET = containers.subnet;
        ALLOWEDIPS = "0.0.0.0/0,${containers.each.dns}/32,${containers.remote},${containers.subnet}";
        PEERS = allPeers;
        SERVERPORT = builtins.toString containers.container;
        PEERDNS = containers.each.dns;
        PERSISTENTKEEPALIVE_PEERS = "all";
      };
      environmentFiles = [ /data/containers/wireguard/env/wire.env ];
      volumes = [
        "/data/containers/wireguard/config:/config"
      ];
      ports = [
        "${builtins.toString containers.original}:${builtins.toString containers.container}/udp"
      ];
      extraOptions = [ "--cap-add=NET_ADMIN" "--network=${containers.name}" "--ip=${containers.each.wire}" ];
    };

    #######
    # DNS #
    #######

    dns-up = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.dns;
      extraOptions = [ "--network=${containers.name}" "--ip=${containers.each.dnsUp}" ];
    };
    dns = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = config.mine.system.timezone;
        DNSMASQ_LISTENING = "all";
        PIHOLE_DNS_ = containers.each.dnsUp;
      };
      dependsOn = [ "dns-up" ];
      environmentFiles = [ /data/containers/pihole/env/adblock.env ];
      volumes = [
        "/data/containers/pihole/config/etc:/etc/pihole"
        "/data/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
        # Own DNS list
        "/data/containers/pihole/config/routes.list:/etc/pihole/custom.list"
      ];
      extraOptions = [ "--dns=127.0.0.1" "--network=${containers.name}" "--ip=${containers.each.dns}" ];
    };

  };


}