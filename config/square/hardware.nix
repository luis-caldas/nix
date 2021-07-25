{ lib, ... }:
{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ata_piix" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "circle/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "circle/home";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "circle/data";
      fsType = "zfs";
      options = [ "nofail" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/62A4-F0F5";
      fsType = "vfat";
    };

  swapDevices = [
    { device = "/dev/zvol/circle/swap"; }
  ];


  nix.maxJobs = lib.mkDefault 4;
}
