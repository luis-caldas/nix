{ lib, config, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  fileSystems."/" =
    { device = "swamp/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F115-254A";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "swamp/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "swamp/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "swamp/tmp";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/zvol/swamp/swap"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "23.05";

}
