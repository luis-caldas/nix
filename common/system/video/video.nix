{ config, pkgs, ... }:
let
  my = import ../../../config.nix;
  upkgs = import
    (builtins.fetchGit "https://github.com/nixos/nixpkgs")
    { config = config.nixpkgs.config; };
in
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
  hardware.opengl = {
    enable = true;
    package = upkgs.mesa.drivers;
  };

}
