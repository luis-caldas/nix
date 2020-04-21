{ ... }:
{

  # General disk mounting
  fileSystems."/" = {
    device = "zpool/root";
    fsType = "zfs";
  };

  # I don't really need swap on this system
  swapDevices = [];

}
