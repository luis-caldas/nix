{ pkgs, lib, config, modulesPath, ... }:
let

  # The system interfaces
  interfaces = {
    wireguard = "wire";
    local = "ens5";
  };

  # Agreed on ports
  wireguardPort = pkgs.networks.ports.simple;

in {

  # My own part of configuring
  mine = {
    minimal = true;
    zram = true;
    boot.override = true;
    system.hostname = "vps";
    network.mac = "permanent";
    user.admin = false;
    services.ssh = true;
    services.prometheus.enable = true;
    services.prometheus.password = "/data/prometheus/pass";
  };

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

  # DNS servers
  networking.networkmanager.insertNameservers = pkgs.networks.dns;

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

  # Firewall setup
  # The firewall will only work after the NAT
  mine.network.firewall.enable = true;
  mine.network.firewall.ping = true;
  networking.firewall = {
    allowedTCPPorts = [
      # Escape port
      pkgs.networks.ports.https;
      # SSH
      (builtins.head config.services.openssh.ports)
      # Prometheus
      config.services.prometheus.port
    ];
    # Allowed UDP
    allowedUDPPorts = [
      wireguardPort
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = pkgs.networks.allowed;
  };

  # Set up our NAT configuration
  networking.nat = {
    enable = true;
    externalInterface = interfaces.local;
    internalInterfaces = [ interfaces.wireguard ];
    forwardPorts = [
      # SSH Port redirection to self
      {
        destination = "${pkgs.networks.tunnel.ips.host}:22";
        proto = "tcp";
        sourcePort = 22;
      }
      # Redirect the VPN ports to self
      {
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString wireguardPort}";
        proto = "udp";
        sourcePort = wireguardPort;
      }
      # Redirect all the rest to tunnel
      {
        destination = "${pkgs.networks.tunnel.ips.remote}:1-${builtins.toString pkgs.networks.ports.end}";
        proto = "tcp";
        sourcePort = "1:${builtins.toString pkgs.networks.ports.end}";
      }
      {
        destination = "${pkgs.networks.tunnel.ips.remote}:1-${builtins.toString pkgs.networks.ports.end}";
        proto = "udp";
        sourcePort = "1:${builtins.toString pkgs.networks.ports.end}";
      }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${interfaces.wireguard}" = {
    ips = [ "${pkgs.networks.tunnel.ips.host}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
    listenPort = wireguardPort;
    privateKeyFile = "/data/wireguard/host.key";
    peers = [{
      publicKey = lib.strings.fileContents /data/wireguard/remote.pub;
      presharedKeyFile = "/data/wireguard/remote.shared.key";
      allowedIPs = [ "${pkgs.networks.tunnel.ips.remote}/32" ];
    }{
      publicKey = lib.strings.fileContents /data/wireguard/vpn.pub;
      presharedKeyFile = "/data/wireguard/vpn.shared.key";
      allowedIPs = [ "${pkgs.networks.tunnel.ips.vpn}/32" ];
    }{
      publicKey = lib.strings.fileContents /data/wireguard/macaco.pub;
      presharedKeyFile = "/data/wireguard/macaco.shared.key";
      allowedIPs = [ "${pkgs.networks.tunnel.ips.macaco}/32" ];
    }];
  };

  # User keys for ssh
  users.users."${config.mine.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/keys
  ];

  # Filesystems

  # Add swap
  swapDevices = [ {
    device = "/swapfile";
    size = 4 * 1024;
  } ];

  system.stateVersion = "23.05";

}
