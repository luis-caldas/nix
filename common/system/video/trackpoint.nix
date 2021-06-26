{ my, ... }:
{

  # Enable libinput for trackpoint
  services.xserver.libinput = {
    enable = true;
  };

  # Enable hardware trackpoint
  hardware.trackpoint = {
      enable = true;
      emulateWheel = true;
      speed = my.config.graphical.trackpoint.speed;
      sensitivity = my.config.graphical.trackpoint.sense;
  };

}
