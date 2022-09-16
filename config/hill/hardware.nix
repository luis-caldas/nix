{ my, lib, config, ... }:
{

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "uas" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  # Set up docker containers
  virtualisation.oci-containers.containers = {
    test = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      ports = [
        "80:8080/tcp"
      ];
    };
  };

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

  system.stateVersion = "21.11";

}
