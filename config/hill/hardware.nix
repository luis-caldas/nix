{ lib, config, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  fileSystems."/" =
    { device = "valley/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E119-AD3C";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "valley/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "valley/tmp";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "valley/home";
      fsType = "zfs";
    };

    swapDevices = [ { device = "/dev/zvol/valley/swap"; } ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "23.05";

}
