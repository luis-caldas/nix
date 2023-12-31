{ pkgs, lib, config, modulesPath, ... }: let

  # Information for the wireguard and NAT networking
  networkInfo = {
    # Networking IP range
    host = "10.255.255.254";
    remote = "10.255.255.1";
    prefix = 24;
    # Original Wireguard port
    original = 51820;
    # Default Wireguard port
    port = 123;
    # Interfaces for Wireguard and NAT
    external = "ens5";
    interface = "wire0";
    # Subnet for secondary Wireguard
    subnet = "10.255.254.0";
    # Gap for internal communication
    gap = 49152;
    # Docker configuration
    docker = {
      name = "internal";
      interface = "int0";
      # Internal docker IPs
      range = "172.16.50.0/24";
      dnsUp = "172.16.50.10";
      dns = "172.16.50.11";
      wire = "172.16.50.20";
      # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
      # Therefore high change of not being blocked
      # Complete range is 3478 -> 3481
      # Port needs also be opened on hosting side
      container = 3478;
    };

  };

in {

  # My own part of configuring
  mine = {
    minimal = true;
    zram = true;
    boot.override = true;
    system.hostname = "vps";
    user.admin = false;
    services.ssh = true;
    services.docker = true;
  };

  # Clear boot configuration
  boot.loader = lib.mkForce {};

  # Force IP parameters
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

  # Needed for virutalisation
  imports = [ (modulesPath + "/virtualisation/amazon-image.nix") ];

  # DNS servers
  networking.networkmanager.insertNameservers = [ "127.0.0.1" ];
  networking.networkmanager.appendNameservers = [ "9.9.9.10" ];

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Firewall setup
  # The firewall will only work after the NAT
  networking.firewall = {
    enable = lib.mkForce true;
    allowedTCPPorts = [
      22    # SSH port
    ];
    allowedUDPPorts = [
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"         # Loopback subnet
      "10.0.0.0/8"          # Local subnet
      "192.168.0.0/16"      # Local subnet
      "172.17.0.0/16"       # Docker subnet
    ];
  };

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

  # User keys for ssh
  users.users."${config.mine.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/keys
  ];

  # Set up the networking creation service
  systemd.services = pkgs.containerFunctions.addNetworks {
    "${networkInfo.docker.name}" = { range = networkInfo.docker.range; interface = networkInfo.docker.interface; };
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
        INTERNAL_SUBNET = networkInfo.subnet;
        ALLOWEDIPS = "0.0.0.0/0,${networkInfo.docker.dns}/32,${networkInfo.remote}/${builtins.toString networkInfo.prefix}";
        PEERS = allPeers;
        SERVERPORT = builtins.toString networkInfo.docker.container;
        PEERDNS = networkInfo.docker.dns;
        PERSISTENTKEEPALIVE_PEERS = "all";
      };
      environmentFiles = [ /data/containers/wireguard/env/wire.env ];
      volumes = [
        "/data/containers/wireguard/config:/config"
      ];
      extraOptions = [ "--cap-add=NET_ADMIN" "--network=${networkInfo.docker.name}" "--ip=${networkInfo.docker.wire}" ];
    };

    #######
    # DNS #
    #######

    dns-up = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.dns;
      extraOptions = [ "--network=${networkInfo.docker.name}" "--ip=${networkInfo.docker.dnsUp}" ];
    };
    dns = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = config.mine.system.timezone;
        DNSMASQ_LISTENING = "all";
        PIHOLE_DNS_ = networkInfo.docker.dnsUp;
      };
      dependsOn = [ "dns-up" ];
      environmentFiles = [ /data/containers/pihole/env/adblock.env ];
      volumes = [
        "/data/containers/pihole/config/etc:/etc/pihole"
        "/data/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
        # Own DNS list
        "/data/containers/pihole/config/routes.list:/etc/pihole/custom.list"
      ];
      extraOptions = [ "--dns=127.0.0.1" "--network=${networkInfo.docker.name}" "--ip=${networkInfo.docker.dns}" ];
    };

  };

  # Filesystems

  # Add swap
  swapDevices = [ {
    device = "/swapfile";
    size = 4 * 1024;
  } ];

  system.stateVersion = "23.05";

}
