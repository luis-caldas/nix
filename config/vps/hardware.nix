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

  # Firewall setup
  networking.firewall.enable = lib.mkForce true;
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"
    ];
  };

  # SSH setup
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = lib.mkForce "no";
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

  # Custom service
  systemd.services.frpd = {
    description = "Fast Reverse Proxy Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    restartIfChanged = true;
    serviceConfig = {
      ExecStart = "${pkgs.frp}/bin/frps --config ${./frps.ini}";
      EnvironmentFile = "/safe/env/frp.env";
      Restart = "always";
    };
  };

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
