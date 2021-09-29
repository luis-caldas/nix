{ pkgs, ... }:
{

  # Set program to change backlight
  programs.light.enable = true;

  # Other needed packages
  environment.systemPackages = with pkgs; [

    # Package for locking the screen
    alock

  ];

}
