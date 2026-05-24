{ lib, config, pkgs, ... }:

lib.mkIf config.mine.audio

{

  # Enable rtkit for audio
  security.rtkit.enable = true;

  # Disable pulseaudio
  services.pulseaudio.enable = false;

  # Pipewire config
  services.pipewire = {

    # Enable pipewire
    enable = true;
    wireplumber.enable = true;

    # Enable other audio systems support
    alsa.enable = true;
    alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    pulse.enable = true;
    jack.enable = true;

  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

}
