{ my, lib, config, modulesPath, pkgs, mfunc, ... }: let

  # Information for the wireguard and NAT networking
  networkInfo = {
    host = "10.1.0.1";
    remote = "10.1.0.2";
    prefix = 16;
    port = 123;
    external = "enp1s0";
    interface = "wg0";
  };

in {

  # Clear boot configuration and force kernel parameters
  boot = lib.mkForce {
    kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
    kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;
    kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
  };

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
    allowPing = lib.mkForce false;
    allowedTCPPorts = [
      22    # SSH port
    ];
    allowedUDPPorts = [
      networkInfo.port
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
      # Redirect the VPN port to self
      { destination = "${networkInfo.host}:${builtins.toString networkInfo.port}"; proto = "udp"; sourcePort = networkInfo.port; }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${networkInfo.interface}" = {
    ips = [ "${networkInfo.host}/${builtins.toString networkInfo.prefix}" ];
    listenPort = networkInfo.port;
    privateKeyFile = "/data/local/wireguard/host.key";
    peers = [{
      publicKey = mfunc.safeReadFile /data/local/wireguard/remote.pub;
      presharedKeyFile = "/data/local/wireguard/shared.key";
      allowedIPs = [ "${networkInfo.remote}/32" ];
    }];
  };

  system.stateVersion = "23.05";

}
