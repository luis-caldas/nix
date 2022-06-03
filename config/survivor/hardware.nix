{ my, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "uhci_hcd" "ehci_pci" "xhci_pci" "ata_piix" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  fileSystems."/" =
    { device = "wilson/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "wilson/home";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "wilson/tmp";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "wilson/nix";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F814-164C";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/3F2B-D291";
      fsType = "vfat";
      options = [ "rw" "uid=${builtins.toString my.config.user.uid}" "gid=${builtins.toString my.config.user.gid}" "nofail" ];
    };

  swapDevices = [ ];

  system.stateVersion = "21.11";

}
