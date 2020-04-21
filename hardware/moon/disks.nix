{ ... }:
{

  # Tell the system that this luks device exists
  boot.initrd.luks.devices."nixor".device = "/dev/disk/by-uuid/2afde2a8-0d37-4fa5-a20d-c63ef994381f";

  # General disk mounting
  fileSystems."/" = {
    device = "kwool/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "kwool/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D649-527B";
    fsType = "vfat";
  };

  fileSystems."/strongo" = {
    device = "/dev/disk/by-label/Strongo";
    fsType = "btrfs";
  };

  # I don't really need swap on this system
  swapDevices = [];

}
