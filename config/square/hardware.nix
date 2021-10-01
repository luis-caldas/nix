{ lib, ... }:
{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ata_piix" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices."rounder".device = "/dev/disk/by-uuid/321b6380-542d-4a07-b653-57bae44733de";

  fileSystems."/" =
    { device = "circle/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "circle/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/DB65-255D";
      fsType = "vfat";
    };

  nix.maxJobs = lib.mkDefault 4;
}
