{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "radeon" "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # ZSwap
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.max_pool_percent=20"
    "zswap.shrinker_enabled=1"
    "zswap.compressor=lz4"
  ];
  # Swappiness
  boot.kernel.sysctl."vm.swappiness" = 10;

  # WiFi Regulatory Domain
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="IE"
  '';

  # Monado
  services.monado.enable = true;
  services.monado.defaultRuntime = true;

  # Display
  hardware.display = let
    file = ./nec-v72.bin;
    port = "DVI-I-1";
    target = "target.bin";
  in {
    edid.enable = true;
    edid.packages = [
      (pkgs.runCommand "nec-v72-edid" {} ''
        mkdir -p "$out/lib/firmware/edid"
        cp ${file} "$out/lib/firmware/edid/${target}"
      '')
    ];
    outputs."${port}" = {
      edid = target;
    };
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Picking primaries
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:0d:00.0", TAG+="mutter-device-preferred-primary"
  '';

  # Drivers
  services.xserver.videoDrivers = [ "radeon" "amdgpu" ];

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
      simple = true;
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
    { device = "/dev/disk/by-uuid/3FF1-6D0E";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

  fileSystems."/" =
    { device = "knight/safe/system/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "knight/safe/system/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "knight/safe/system/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "knight/safe/system/tmp";
      fsType = "zfs";
    };

  swapDevices = [{
    device = "/dev/disk/by-partuuid/3eeb2625-47cf-4282-a8c2-cc8de9e5f874";
    randomEncryption.enable = true;
  }];

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # State initialisation version
  system.stateVersion = "25.05";

}
