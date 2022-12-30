{ lib, ... }:
{
  imports = [
    ./custom/pinebook_pro.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "pinebookpro-ap6256-firmware"
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

  swapDevices = [ {
    device = "/swappers";
    size = (1024 * 4); # Size in MB
  } ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

}
