{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  # Show windows boot options
  boot.loader.systemd-boot.windows."11" = {
    title = "Windows";
    efiDeviceHandle = "HD1b";
    sortKey = "m_windows";
  };

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # Monado
  services.monado.enable = true;
  services.monado.defaultRuntime = true;

  # My specific configuration
  mine = {
    services = {
      ssh = false;
      avahi = true;
      docker = true;
      printing = true;
      virtual = {
        enable = true;
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
    { device = "/dev/disk/by-uuid/3FF1-6D0E";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/" =
    { device = "knight/safe/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "knight/safe/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "knight/safe/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "knight/safe/tmp";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "knight/safe/data";
      fsType = "zfs";
    };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/3eeb2625-47cf-4282-a8c2-cc8de9e5f874";
      randomEncryption.enable = true;
    }
  ];

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # State initialisation version
  system.stateVersion = "25.05";

}
