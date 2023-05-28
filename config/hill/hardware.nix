{ my, lib, config, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  fileSystems."/" =
    { device = "hill/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/669A-8E94";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "hill/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "hill/tmp";
      fsType = "zfs";
    };

  # Second disk
  fileSystems."/safe" =
    { device = "hill/safe";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "mound/home";
      fsType = "zfs";
      depends = [ "/safe" ];
    };

  fileSystems."/data" =
    { device = "mound/safe";
      fsType = "zfs";
      depends = [ "/safe" ];
    };

  fileSystems."/store" =
    { device = "mound/store";
      fsType = "zfs";
      depends = [ "/safe" ];
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
