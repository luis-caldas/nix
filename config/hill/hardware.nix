{ my, lib, config, ... }:
{

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "uas" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "intel_iommu=on" "i915.enable_guc=0" "i915.enable_gvt=1" ];

  boot.zfs.requestEncryptionCredentials = true;

  fileSystems."/" =
    { device = "hill/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E4B6-6B03";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "hill/data";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "hill/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "hill/home";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "hill/tmp";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
