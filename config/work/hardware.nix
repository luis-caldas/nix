{ lib, config, pkgs, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  imports = let
    framework = builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware"; };
  in [
    "${framework}/framework/13-inch/7040-amd"
  ];

  # Disable fingerprint
  services.fprintd.enable = false;

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
