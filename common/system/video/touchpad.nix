{ my, ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = false;
    disableWhileTyping = true;
    accelSpeed = my.config.graphical.touchpad.accel;
  };

}
