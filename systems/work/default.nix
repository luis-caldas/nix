{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "uas" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "thunderbolt" "vfio-iommu-type1" ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hardware from NixOS
  imports = [
    "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware"; }}/framework/13-inch/7040-amd"
  ];

  # eGPU
  services.udev.extraRules = ''
    # eGPU for Gnome
    ENV{DEVNAME}=="/dev/dri/card1", TAG+="mutter-device-preferred-primary"
  '';

  # Disable fingerprint
  services.fprintd.enable = false;

  # My specific configuration
  mine = {
    boot.timeout = 1;
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
