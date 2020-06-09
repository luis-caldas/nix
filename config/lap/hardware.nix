{ lib, ... }:
{
  imports = [ 
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ] ++ [
    ./custom/pinebook_pro.nix 
  ];
 
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];

  nixpkgs.config.allowUnfree = true;
 
  boot.initrd.luks.devices."chest".device = "/dev/disk/by-uuid/433b78d2-9fe4-4e9a-b881-9901a23ec27d";

  fileSystems."/" =
    { device = "lappy/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "lappy/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C1F0-D964";
      fsType = "vfat";
    };

  fileSystems."/emcol" =
    { device = "emco";
      fsType = "zfs";
      encrypted = { enable = true;
                    blkDev = "/dev/disk/by-uuid/b41b6c61-719d-44a1-989a-92a3a77268ea";
                    label = "emmm";
                    keyFile = "/mnt-root/keys/emmc.key";
                  };
    };

  swapDevices = [{ device = "/dev/zvol/lappy/swap"; }];

  nix.maxJobs = lib.mkDefault 6;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

}
