{ my, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "uhci_hcd" "ehci_pci" "xhci_pci" "ata_piix" "ahci" "usbhid" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  fileSystems."/" =
    { device = "carry/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "carry/home";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "carry/tmp";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "carry/nix";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/CE8E-F425";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/CF7D-DD7B";
      fsType = "vfat";
      options = [ "rw" "uid=${builtins.toString my.config.user.uid}" "gid=${builtins.toString my.config.user.gid}" "nofail" ];
    };

  swapDevices = [ ];

  system.stateVersion = "21.11";

}
