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
    # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
    # Therefore high change of not being blocked
    # Complete range is 3478 -> 3481
    # Port needs also be opened on hosting side
    container = 3478;
    # Subnet for secondary Wireguard
    subnet = "10.255.254.0";
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
  networking.networkmanager.insertNameservers = [ "9.9.9.10" "149.112.112.10" ];

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
      networkInfo.container
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"         # Local subnet
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
    enable = true;
    externalInterface = networkInfo.external;
    internalInterfaces = [ networkInfo.interface ];
    dmzHost = networkInfo.remote;
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
        destination = "${networkInfo.host}:${builtins.toString networkInfo.container}";
        proto = "udp";
        sourcePort = networkInfo.container;
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

  # Wireguard containarised for real VPNs
  virtualisation.oci-containers.containers = {
    wireguard = let
      DEFAULT_PORT = builtins.toString 51820;
      newPort = builtins.toString networkInfo.container;
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
        SERVERURL = "auto";
        SERVERPORT = newPort;
        PEERDNS = "auto";
      };
      volumes = [
        "/data/containers/wireguard:/config"
      ];
      ports = [
        "${newPort}:${DEFAULT_PORT}/udp"
      ];
      extraOptions = [ "--cap-add=NET_ADMIN" ];
    };
  };

  # Add swap
  swapDevices = [ {
    device = "/swapfile";
    size = 4 * 1024;
  } ];

  system.stateVersion = "23.05";

}
