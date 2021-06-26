{ my, ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      disableWhileTyping = true;
      accelSpeed = my.config.graphical.touchpad.accel;
    };
  };

}
