{ config, lib, pkgs, modulesPath, ... }:
{

  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices."mountain".device = "/dev/disk/by-uuid/b1e8d0a6-e8c8-4470-90d4-5fd122977429";

  fileSystems."/" =
    { device = "hill/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F3D9-C934";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "hill/home";
      fsType = "zfs";
    };
    
  fileSystems."/data" =
    { device = "hill/data";
    fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

}
