{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ "thunderbolt" "xhci_hcd" ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # Hardware from NixOS
  imports = [
    "${builtins.fetchGit "https://github.com/NixOS/nixos-hardware"}/framework/13-inch/7040-amd"
  ];

  # WiFi Regulatory Domain
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="IE"
  '';

  boot.kernelParams = [

    # ZSwap
    "zswap.enabled=1"
    "zswap.max_pool_percent=20"
    "zswap.shrinker_enabled=1"
    "zswap.compressor=lz4"

    # AMD Fix
    "amdgpu.sg_display=0"
    "amdgpu.mcbp=0"

  ];

  # Disable fingerprint
  services.fprintd.enable = false;

  # My specific configuration
  mine = {
    boot.secure = true;
    services = {
      ssh = false;
      avahi = true;
      printing = true;
      fwupd = true;
      docker = {
        enable = true;
        manager = true;
      };
      virtual = {
        enable = true;
        manager = true;
        swtpm = true;
        android = true;
      };
    };
    graphics = {
      enable = true;
      cloud = true;
    };
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

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/222B-4DD8";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

  fileSystems."/" =
    { device = "dark/safe/system/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "dark/safe/system/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "dark/safe/system/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "dark/safe/system/tmp";
      fsType = "zfs";
    };

  swapDevices = [{
    device = "/dev/disk/by-partuuid/cb8d5e6b-251f-4661-a31b-a2d925b90528";
    randomEncryption.enable = true;
  }];

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # State initialisation version
  system.stateVersion = "23.05";

}
