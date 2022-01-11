{ lib, ... }:
{
  imports = [
    ./custom/pinebook_pro.nix
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/bf0e68e6-dc1d-4c92-b456-6b427059ae2a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/05DA-50FC";
      fsType = "vfat";
    };

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

}
