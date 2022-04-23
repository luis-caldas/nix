{ my, mfunc, config, lib, ... }:
{

  # Import kodi
  imports = [ ./kodi.nix ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Some containers
  virtualisation.oci-containers.containers = {
    media = {
      image = "local/python-scrape";
      imageFile = my.containers.pythonScrape;
      environment = {
        "SMTP_USER" = mfunc.safeReadFile /data/safe/smtp_user;
        "SMTP_SERVER" = mfunc.safeReadFile /data/safe/smtp_server;
        "SMTP_PASSWORD" = mfunc.safeReadFile /data/safe/smtp_password;
        "SMTP_MAIL_TO" = mfunc.safeReadFile /data/safe/smtp_mail_to;
      };
    };
  };

  fileSystems."/" =
    { device = "light/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/40FB-1D4B";
      fsType = "vfat";
    };

  fileSystems."/tmp" =
    { device = "light/tmp";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "light/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "light/nix";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "light/data";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

}
