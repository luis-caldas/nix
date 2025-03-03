{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # My specific configuration
  mine = {
    services = {
      ssh = true;
      avahi = true;
      docker = true;
      printing = true;
      virtual = {
        enable = true;
        swtpm = true;
      };
    };
  };

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  # File systems

  # Boot

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C310-CD09";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/keys" =
    { device = "skib/safe/keys";
      fsType = "zfs";
      neededForBoot = true;
    };

  # System


  fileSystems."/" =
    { device = "skib/safe/system/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "skib/safe/system/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "skib/safe/system/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "skib/safe/system/tmp";
      fsType = "zfs";
    };

  # Data

  fileSystems."/data/local" =
    { device = "skib/safe/data";
      fsType = "zfs";
    };

  fileSystems."/data/chung" =
    { device = "chungus/safe/data";
      fsType = "zfs";
    };

  # Swap

  swapDevices =
    [ { device = "/dev/disk/by-partuuid/b4b59e25-4a48-46fd-82cc-a9f3148351f3";
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