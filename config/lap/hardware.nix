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

  boot.initrd.luks.devices."emmm".device = "/dev/disk/by-uuid/b41b6c61-719d-44a1-989a-92a3a77268ea";

  fileSystems."/" =
    { device = "emco/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "emco/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C1F0-D964";
      fsType = "vfat";
    };

  nix.maxJobs = lib.mkDefault 6;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

}
