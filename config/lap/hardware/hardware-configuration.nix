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

  nixpkgs.config.allowUnfree = true;
 
  boot.initrd.luks.devices."chest".device = "/dev/disk/by-uuid/624c6b9c-1f0b-429e-a84f-eab22254217b";

  fileSystems."/" =
    { device = "coro/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "coro/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C1F0-D964";
      fsType = "vfat";
    };

  # swapDevices = [{device = "/dev/zvol/coro/swap";}];
  # dont know if ill need this yet

  nix.maxJobs = lib.mkDefault 6;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

}
