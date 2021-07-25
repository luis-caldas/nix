{ config, lib, pkgs, ... }:
{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ata_piix" "ahci" "firewire_ohci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Tell the system that this luks device exists
  boot.initrd.luks.devices."rad".device = "/dev/disk/by-uuid/44482a86-475c-4acf-a9e6-44e4a08f57e1";

  fileSystems."/" =
    { device = "plat/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/DE1C-9AA1";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "plat/home";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "plat/data";
      fsType = "zfs";
      options = [ "nofail" ];
    };

  swapDevices = [ { device = "/dev/disk/by-uuid/d0257465-4d20-4412-acd7-c2ec84d9f98a"; } ];

  nix.maxJobs = lib.mkDefault 2;

  hardware.enableRedistributableFirmware = true;
  # networking.enableIntel3945ABGFirmware = true;

}
