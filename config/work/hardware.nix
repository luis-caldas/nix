{ lib, config, pkgs, upkgs, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  boot.kernelPackages = upkgs.linuxKernel.packages.linux_6_5;

  imports = let
    framework = builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware"; };
  in [
    "${framework}/framework/13-inch/7040-amd"
  ];

  services.fprintd.enable = false;
  services.fwupd.enable = true;

  fileSystems."/" =
    { device = "dark/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6D1A-B930";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "dark/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "dark/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "dark/tmp";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/zvol/dark/swap"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "23.05";

}
