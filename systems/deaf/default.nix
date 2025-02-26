{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # My specific configuration
  mine = {
    system.hostname = "deaf";
    services = {
      ssh = false;
      avahi = true;
      docker = true;
      printing = true;
      virtual = {
        enable = true;
        swtpm = true;
        android = true;
        vmware = true;
      };
    };
    graphics.enable = true;
    production = {
      audio = true;
      models = true;
      software = true;
      business = true;
      electronics = true;
    };

    audio = true;
    bluetooth = true;
    games = true;
  };

  # Packages
  environment.systemPackages = with pkgs; [
    vmware-horizon-client
  ];

  # File systems

  # Boot

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/48AB-6331";
      fsType = "vfat";
    };

  # System

  fileSystems."/" =
    { device = "seac/safe/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "seac/safe/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "seac/safe/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "seac/safe/tmp";
      fsType = "zfs";
    };

  # Data

  fileSystems."/data" =
    { device = "seac/safe/data";
      fsType = "zfs";
    };

  # SWAP

  swapDevices =
    [ {
        device = "/dev/disk/by-partuuid/2d711bec-cde7-4a6d-a80b-bee0e002d1b8";
        randomEncryption.enable = true;
      }
    ];

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # State initialisation version
  system.stateVersion = "24.11";

}
