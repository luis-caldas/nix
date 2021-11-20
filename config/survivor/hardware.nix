{ lib, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "uhci_hcd" "ehci_pci" "xhci_pci" "ata_piix" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices."survivor".device = "/dev/disk/by-uuid/1980e7ba-940a-4030-8ce6-912e4391e8d5";

  fileSystems."/" =
    { device = "survivor/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/09B8-F881";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/0945-46DB";
      fsType = "vfat";
      options = [ "rw" "uid=1000" "gid=1000" "nofail" ];
    };

  fileSystems."/home" =
    { device = "survivor/home";
      fsType = "zfs";
    };

  swapDevices = [ ];

}
