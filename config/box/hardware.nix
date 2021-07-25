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
    { device = "boxy/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "boxy/home";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "boxy/data";
      fsType = "zfs";
      options = [ "nofail" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B0C3-ED9F";
      fsType = "vfat";
    };

  nix.maxJobs = lib.mkDefault 4;
}
