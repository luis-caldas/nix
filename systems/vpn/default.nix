{ pkgs, lib, config, modulesPath, ... }:
let

  # Shared information
  shared = {

    # Overall networking for docker
    networks = pkgs.functions.container.createNetworkNames [
      # Networks
      "wire" "turn"
    ];

    # Set up container names
    names = pkgs.functions.container.createNames { dataIn = {
      # Non split containers
      app = [
        # VPN
        "wire"
        # TURN
        "turn"
      ];
      # DNS
      dns = [ "app" "up" ];
    };};

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

  };

  # Build docker projects
  builtProjects = pkgs.functions.container.projects ./containers shared;

in {

  #######
  # Own #
  #######

  # My own part of configuring
  mine = {
    minimal = true;
    zram = true;
    boot.override = true;
    system.hostname = "vpn";
    network.mac = "permanent";
    user.admin = false;
    services.ssh = true;
    services.docker = true;
    services.prometheus.enable = true;
    services.prometheus.password = "/data/prometheus/pass";
  };

  ########
  # Boot #
  ########

  # Clear boot configuration
  boot.loader = lib.mkForce {};

  # Force IP parameters
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

  # All my imports
  imports = [
    # AWS files
    (modulesPath + "/virtualisation/amazon-image.nix")
  ];

  ##############
  # Networking #
  ##############

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Firewall setup
  # The firewall will only work after the NAT
  mine.network.firewall.enable = true;
  mine.network.firewall.ping = true;
  networking.firewall = {
    allowedTCPPorts = [
      # Escape Port
      pkgs.networks.ports.https
      # SSH
      (builtins.head config.services.openssh.ports)
      # Prometheus
      config.services.prometheus.port
    ];
    allowedUDPPorts = [
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = pkgs.networks.allowed;
  };

  # Set the DNS
  networking.networkmanager.insertNameservers = [
    pkgs.networks.docker.dns.vpn.ips.main
  ] ++ pkgs.networks.dns;

  # User keys for ssh
  users.users."${config.mine.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/keys
  ];

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

  ##############
  # Containers #
  ##############

  # Arion
  virtualisation.arion.projects = builtProjects;

  # Docker dependencies
  systemd.services = pkgs.functions.container.createDependencies builtProjects;

  #############
  # Wireguard #
  #############

  # Set up our wireguard configuration
  networking.wireguard.interfaces.wire = {
    ips = [ "${pkgs.networks.tunnel.ips.vpn}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
    listenPort = pkgs.networks.ports.wireguard;
    privateKeyFile = "/data/wireguard/vpn.key";
    peers = [{
      publicKey = lib.strings.fileContents /data/wireguard/host.pub;
      presharedKeyFile = "/data/wireguard/vpn.shared.key";
      allowedIPs = [ "${pkgs.networks.tunnel.network}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
      endpoint = "${lib.strings.fileContents /data/wireguard/endpoint}:${builtins.toString pkgs.networks.ports.simple}";
      persistentKeepalive = pkgs.networks.alive;
    }];
  };

  ###############
  # Filesystems #
  ###############

  # Add swap
  swapDevices = [ {
    device = "/swapfile";
    size = 4 * 1024;
  } ];

  system.stateVersion = "23.05";

}
