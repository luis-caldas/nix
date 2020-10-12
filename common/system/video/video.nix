{ my, mfunc, config, upkgs, ... }:
{

  # Allow xorg and the whole lot
  services.xserver.enable = true;
  services.xserver.autorun = false;

  # Use startx command to start wm
  services.xserver.displayManager.startx.enable = true;

  # Set graphics drivers
  services.xserver.videoDrivers = my.config.graphical.drivers;

  # Set program to change backlight
  programs.light.enable = true;

  # Program to lock the screen
  programs.slock.enable = true;

  # Force the latest mesa drivers
  hardware.opengl = mfunc.useDefault my.config.graphical.latest {
    enable = true;
    package = upkgs.mesa.drivers;
  } {};

}
