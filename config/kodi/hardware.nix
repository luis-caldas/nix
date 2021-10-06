{ lib, ... }:
{

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "mix/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "mix/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9E27-7BFB";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 2;
}
