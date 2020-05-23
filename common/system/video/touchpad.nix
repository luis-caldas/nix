{ ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = true;
  };

}
