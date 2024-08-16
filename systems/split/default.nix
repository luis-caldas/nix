{ pkgs, lib, config, ... }:
{

  ########
  # Boot #
  ########

  # Modules for startup
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ "pcie_aspm=off" "amd_iommu=on" "iommu=pt" "pci=noaer" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  #######
  # Own #
  #######

  # My own configuration
  mine = {
    minimal = true;
    system.hostname = "split";
    user.admin = false;
    services = {
      ssh = true;
      docker = true;
      virtual.enable = true;
      prometheus = {
        enable = true;
        password = "/data/local/prometheus/pass";
      };
    };
  };

  ##################
  # Virtualisation #
  ##################

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  #######
  # UPS #
  #######

  # UPS client
  power.ups = {

    enable = true;
    mode = "netclient";
    schedulerRules = "${pkgs.functions.ups.clientSched}";

    # UPS Monitor
    upsmon = {

      # Connection
      monitor.main = {
        system = "apc@router";
        powerValue = 1;
        user = "admin";
        passwordFile = "/data/local/nut/pass";
        type = "secondary";
      };

      # Settings
      settings = pkgs.functions.ups.sharedConf // {
        # Binary Scheduler
        NOTIFYCMD = "${pkgs.nut}/bin/upssched";
        # Flags to be notified
        NOTIFYFLAG = pkgs.functions.ups.mapNotifyFlags [
          "ONLINE" "ONBATT"
        ] pkgs.functions.ups.defaultNotify;
      };

    };

  };

  ################
  # File Systems #
  ################

  fileSystems."/" =
    { device = "slip/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/97DC-3076";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/home" =
    { device = "slip/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "slip/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "slip/tmp";
      fsType = "zfs";
    };

  fileSystems."/vm" =
    { device = "slip/vm";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d30cf88f-f82a-48b6-9815-9e2451876f47"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "24.05";

}
