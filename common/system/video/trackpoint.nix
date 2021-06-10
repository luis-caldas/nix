{ my, ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    touchpad.scrollButton = 2;
  };

}
