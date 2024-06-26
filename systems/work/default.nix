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

  # eGPU
  services.udev.extraRules = ''
    # eGPU for Gnome
    ENV{DEVNAME}=="/dev/dri/card1", TAG+="mutter-device-preferred-primary"
  '';

  # Disable fingerprint
  services.fprintd.enable = false;

  # My specific configuration
  mine = {
    system.hostname = "work";
    services = {
      ssh = false;
      avahi = true;
      docker = true;
      printing = true;
      virtual.enable = true;
      virtual.android = true;
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

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # State initialisation version
  system.stateVersion = "23.05";

}
