{ pkgs, ... }:
{

  # Add custom drivers and xorg files
  services.xserver.videoDrivers = ["nouveau"];

}
