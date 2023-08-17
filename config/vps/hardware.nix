{ my, lib, config, modulesPath, pkgs, ... }:
{

  # Needed for virutalisation
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # Boot information
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  # DNS servers
  networking.networkmanager.insertNameservers = [ "1.1.1.1" "1.0.0.1" ];

  # Some kernel config
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

  # Firewall setup
  networking.firewall = {
    enable = lib.mkForce true;
    allowedTCPPorts = [
      22    # SSH port
    ];
  };
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"         # Local subnet
      "172.17.0.0/16"       # Docker subnet
    ];
  };

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
  users.users.lakituen = {
    isNormalUser  = true;
    home = "/home/lakituen";
    openssh.authorizedKeys.keyFiles = [
      /etc/nixos/ssh/extra
    ];
  };

  # Wireguard containarised
#  virtualisation.oci-containers.containers = {
#    wireguard = {
#      image = "lscr.io/linuxserver/wireguard:latest";
#      environment = {
#        TZ = my.config.system.timezone;
#        PUID = builtins.toString my.config.user.uid;
#        GUID = builtins.toString my.config.user.gid;
#        INTERNAL_SUBNET = "192.168.100.1";
#        PEERS = "phone,laptop";
#        SERVERURL = "auto";
#        SERVERPORT = "51820";
#        PEERDNS = "auto";
#      };
#      volumes = [
#        "/data/local/wireguard:/config"
#      ];
#      ports = [
#        "51820:51820/udp"
#      ];
#      extraOptions = [ "--cap-add=NET_ADMIN" ];
#    };
#  };

  # Custom service
#  systemd.services.frpd = {
#    description = "Fast Reverse Proxy Server";
#    wantedBy = [ "multi-user.target" ];
#    after = [ "network.target" ];
#    restartIfChanged = true;
#    serviceConfig = {
#      ExecStart = "${pkgs.frp}/bin/frps --config ${./frps.ini}";
#      EnvironmentFile = "/safe/env/frp.env";
#      Restart = "always";
#    };
#  };

  # File systems and SWAP
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  swapDevices = [ {
    device = "/swapfile";
    size = (1024 * 4); # Size in MB
  } ];

}
