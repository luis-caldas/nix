{ lib, ... }:
{
  imports = [ 
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ] ++ [
    ../custom/pinebook_pro.nix 
  ];
 
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.initrd.availableKernelModules = [ "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.config.allowUnfree = true;
 
  networking.hostId = "12345678";
 
  boot.initrd.luks.devices."chest".device = "/dev/disk/by-uuid/6a5e57a2-5b12-4776-b945-b5126403cc60";

  fileSystems."/" =
    { device = "coro/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "coro/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9EF9-607D";
      fsType = "vfat";
    };

  swapDevices = [{device = "/dev/zvol/coro/swap";}];

  nix.maxJobs = lib.mkDefault 6;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

}
