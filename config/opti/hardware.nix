{ my, mfunc, config, lib, ... }:
{

  # Import kodi
  imports = [ ./kodi.nix ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # UPS client
  power.ups = {
    enable = true;
    mode = "netclient";
    schedulerRules = "/data/nut/upssched.conf";
  };
  users = {
    users.nut = {
      isSystemUser = true;
      group = "nut";
      home = "/var/lib/nut";
      createHome = true;
    };
    groups.nut = { };
  };
  environment.etc = {
    "nut/upsmon.conf".source = "/data/nut/upsmon.conf";
  };
  systemd.services.upsd = lib.mkForce {};
  systemd.services.upsdrv = lib.mkForce {};

  # Some containers
  virtualisation.oci-containers.containers = {
    media = {
      image = "local/python-scrape";
      imageFile = my.containers.pythonScrape;
      environmentFiles = [ /data/safe/smtp.env ];
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

  system.stateVersion = "21.11";

}
