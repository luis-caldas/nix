{ lib, ... }:
{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "nvme" "uhci_hcd" "ehci_pci" "xhci_pci" "ata_piix" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices."survivor".device = "/dev/disk/by-uuid/31d1f937-8f73-40ec-a8d1-cfc8fc13d5dd";

  fileSystems."/" =
    { device = "survivor/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/09B8-F881";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/9A19-A1D9";
      fsType = "vfat";
      options = [ "uid=1000" "gid=1000" ];
    };

  fileSystems."/home" =
    { device = "survivor/home";
      fsType = "zfs";
    };

  swapDevices = [ ];

}
