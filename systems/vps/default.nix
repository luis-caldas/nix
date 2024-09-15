{ pkgs, lib, config, modulesPath, ... }:
let

  # The system interfaces
  interfaces = {
    wireguard = "wire";
    local = "enX0";
  };

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
      pkgs.networks.ports.https
      # SSH
      (builtins.head config.services.openssh.ports)
      # Prometheus
      config.services.prometheus.port
      # TURN
      pkgs.networks.ports.turn
    ];
    # Allowed UDP
    allowedUDPPorts = [
      # Wireguard
      pkgs.networks.ports.simple
      # TURN
      pkgs.networks.ports.turn
    ];
    allowedUDPPortRanges = [
      (with config.services.coturn; {
        from = min-port;
        to = max-port;
      })
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
        proto = "tcp";
        sourcePort = builtins.head config.services.openssh.ports;
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString (builtins.head config.services.openssh.ports)}";
      }
      # Redirect the VPN ports to self
      {
        proto = "udp";
        sourcePort = pkgs.networks.ports.simple;
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString pkgs.networks.ports.simple}";
      }
      # Redirect TURN Ports
      {
        proto = "tcp";
        sourcePort = pkgs.networks.ports.turn;
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString pkgs.networks.ports.turn}";
      }
      {
        proto = "udp";
        sourcePort = pkgs.networks.ports.turn;
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString pkgs.networks.ports.turn}";
      }
      # TURN Traffic Ports
      {
        proto = "udp";
        sourcePort = "${builtins.toString config.services.coturn.min-port}:${builtins.toString config.services.coturn.max-port}";
        destination = "${pkgs.networks.tunnel.ips.host}:${builtins.toString config.services.coturn.min-port}-${builtins.toString config.services.coturn.max-port}";
      }
      # All the remaining traffic can be redirected to the tunnel
      {
        proto = "tcp";
        sourcePort = "1:${builtins.toString pkgs.networks.ports.end}";
        destination = "${pkgs.networks.tunnel.ips.remote}:1-${builtins.toString pkgs.networks.ports.end}";
      }
      {
        proto = "udp";
        sourcePort = "1:${builtins.toString pkgs.networks.ports.end}";
        destination = "${pkgs.networks.tunnel.ips.remote}:1-${builtins.toString pkgs.networks.ports.end}";
      }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${interfaces.wireguard}" = {
    ips = [ "${pkgs.networks.tunnel.ips.host}/${builtins.toString pkgs.networks.tunnel.prefix}" ];
    listenPort = pkgs.networks.ports.simple;
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

  # TURN Server
   services.coturn = rec {
    # Enable
    enable = true;
    # Disable uneeded capabilities
    no-cli = true;
    no-tls = true;
    no-dtls = true;
    no-tcp-relay = true;
    # Networking
    listening-port = pkgs.networks.ports.turn;
    realm = builtins.readFile "/data/turn/realm";
    # Secrets
    use-auth-secret = true;
    secure-stun = true;
    static-auth-secret-file = "/data/turn/secret";
    # Extra config
    extraConfig = ''
      # Debug
      verbose
      # Ban private ranges
      no-multicast-peers
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=240.0.0.0-255.255.255.255
      # Set quota
      user-quota=12
      total-quota=1200
    '';
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
