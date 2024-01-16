{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ "thunderbolt" "xhci_hcd" ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # Use latest kernel
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # Hardware from NixOS
  imports = [
    "${builtins.fetchGit "https://github.com/NixOS/nixos-hardware"}/framework/13-inch/7040-amd"
  ];

  # AMD Fix
  boot.kernelParams = [ "amdgpu.sg_display=0" "amdgpu.mcbp=0" ];

  # Disable fingerprint
  services.fprintd.enable = false;

  # My specific configuration
  mine = {
    system.hostname = "work";
    services = {
      avahi = true;
      docker = true;
      printing = true;
    };
    graphics.enable = true;
    production = {
      audio = true;
      models = true;
      software = true;
      business = true;
      electronics = true;
    };
    audio = true;
    bluetooth = true;
    games = true;
  };

  # File systems

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

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # State initialisation version
  system.stateVersion = "23.05";

}
