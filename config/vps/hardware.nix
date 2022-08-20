{ my, lib, config, modulesPath, ... }:
{

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = lib.mkForce "no";
  };

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

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  swapDevices = [ {
    device = "/swapfile";
    size = (1024 * 4); # Size in MB
  } ];

  system.stateVersion = "22.05";

}
