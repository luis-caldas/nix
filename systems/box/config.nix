{
  boot = {
    timeout = 0;
    default = 0;
    efi = false;
    device = "/dev/sda";
  };
  kernel.params = ["vga=normal" "nomodeset"];
  user = {
    groups = ["docker"];
    autologin = false;
  };
  system.hostname = "box";
  net = {
    interface.main = "enp3s0";
    id = "19719431";
  };
  services = {
    ssh = true;
    docker = true;
  };
  graphical = false;
}
