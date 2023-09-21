{ my, lib, config, modulesPath, pkgs, mfunc, ... }: let

  # Information for the wireguard and NAT networking
  networkInfo = {
    # Networking IP range
    host = "10.255.255.254";
    remote = "10.255.255.1";
    prefix = 24;
    # Default Wireguard port
    port = 123;
    # Interfaces for Wireguard and NAT
    external = "enX0";
    interface = "wg0";
    # Subnet for secondary Wireguard
    subnet = "10.255.254.0";
    # Gap for internal communication
    gap = 49152;
    # Docker configuration
    docker = {
      interface = "internal";
      # Internal docker IPs
      range = "172.16.50.0/24";
      dnsUp = "172.15.50.2";
      dns = "172.15.50.1";
      wire = "172.15.50.10";
      # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
      # Therefore high change of not being blocked
      # Complete range is 3478 -> 3481
      # Port needs also be opened on hosting side
      container = 3478;
    };

  };

in {

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
      networkInfo.port
      networkInfo.docker.container
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

  # SSH setup
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
    };
  };
  # User keys for ssh
  users.users."${my.config.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/authorized_keys
  ];

  # Set up our NAT configuration
  networking.nat = {
    enable = false;
    externalInterface = networkInfo.external;
    internalInterfaces = [ "br-${networkInfo.docker.interface}" networkInfo.interface ];
    forwardPorts = [
      # SSH Port redirection to self
      { destination = "${networkInfo.host}:22"; proto = "tcp"; sourcePort = 22; }
      # Redirect the VPN ports to self
      {
        destination = "${networkInfo.host}:${builtins.toString networkInfo.port}";
        proto = "udp";
        sourcePort = networkInfo.port;
      }
      {
        destination = "${networkInfo.docker.wire}:${builtins.toString networkInfo.docker.container}";
        proto = "udp";
        sourcePort = networkInfo.docker.container;
      }
      # Redirect all the rest to tunnel
      {
        destination = "${networkInfo.remote}:1-${builtins.toString networkInfo.gap}";
        proto = "tcp";
        sourcePort = "1:${builtins.toString networkInfo.gap}";
      }
      {
        destination = "${networkInfo.remote}:1-${builtins.toString networkInfo.gap}";
        proto = "udp";
        sourcePort = "1:${builtins.toString networkInfo.gap}";
      }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${networkInfo.interface}" = {
    ips = [ "${networkInfo.host}/${builtins.toString networkInfo.prefix}" ];
    listenPort = networkInfo.port;
    privateKeyFile = "/data/wireguard/host.key";
    peers = [{
      publicKey = mfunc.safeReadFile /data/wireguard/remote.pub;
      presharedKeyFile = "/data/wireguard/shared.key";
      allowedIPs = [ "${networkInfo.remote}/32" ];
    }];
  };

  # Set up the networking creation service
  systemd.services = my.containers.functions.addNetworks {
    "${networkInfo.docker.interface}" = networkInfo.docker.range;
  };

  # All containers
  virtualisation.oci-containers.containers = {

    # Main client wireguard configuration
    wireguard = let
      DEFAULT_PORT = builtins.toString 51820;
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
        TZ = my.config.system.timezone;
        PUID = builtins.toString my.config.user.uid;
        GUID = builtins.toString my.config.user.gid;
        INTERNAL_SUBNET = networkInfo.subnet;
        PEERS = allPeers;
        SERVERPORT = builtins.toString networkInfo.docker.container;
        PEERDNS = networkInfo.docker.dns;
      };
      environmentFiles = [ /data/containers/wireguard/env/wire.env ];
      volumes = [
        "/data/containers/wireguard/config:/config"
      ];
      ports = [
        "${builtins.toString networkInfo.docker.container}:${DEFAULT_PORT}/udp"
      ];
      extraOptions = [ "--cap-add=NET_ADMIN" "--network=${networkInfo.docker.interface}" "--ip=${networkInfo.docker.wire}" ];
    };

    # DNS configuration
    dns-up = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.dns;
      extraOptions = [ "--network=${networkInfo.docker.interface}" "--ip=${networkInfo.docker.dnsUp}" ];
    };
    dns-block = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = my.config.system.timezone;
        DNSMASQ_LISTENING = "all";
        DNS1 = networkInfo.docker.dnsUp;
        DNS2 = networkInfo.docker.dnsUp;
      };
      environmentFiles = [ /data/containers/pihole/env/adblock.env ];
      volumes = [
        "/data/containers/pihole/config/etc:/etc/pihole"
        "/data/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
      ];
      extraOptions = [ "--dns=127.0.0.1" "--network=${networkInfo.docker.interface}" "--ip=${networkInfo.docker.dns}" ];
    };

  };

  # Add swap
  swapDevices = [ {
    device = "/swapfile";
    size = 4 * 1024;
  } ];

  system.stateVersion = "23.05";

}
