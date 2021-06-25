{ my, ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      disableWhileTyping = true;
      accelSpeed = my.config.graphical.touchpad.accel;
    };
  };

}
