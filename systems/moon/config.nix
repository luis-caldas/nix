{
  boot = {
    timeout = 1;
    default = 2;
    efi = true;
    device = "nodev";
  };
  system.hostname = "moon";
  net = {
    interface.main = "enp4s0";
    id = "19709431";
  };
  services.ssh = true;
  graphical = true;
}
