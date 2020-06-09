{ pkgs, ... }:
{

  # Store audio cards states
  sound.enable = true;

  # Enable pulseaudio and all the supported codecs
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

}
