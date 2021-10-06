{ lib, ... }:
{

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "systemo/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B817-C894";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "systemo/home";
      fsType = "zfs";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
