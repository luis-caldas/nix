{ my, ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    scrollButton = 2;
  };

}
