{ lib, ... }:
{

  # Import kodi
  imports = [ ./kodi.nix ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "opti/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0EC4-EC27";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "opti/home";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "opti/data";
      fsType = "zfs";
      options = [ "nofail" ];
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
