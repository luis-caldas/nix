{ lib, config, pkgs, ... }:

lib.mkIf config.mine.audio

{

  # Enable rtkit for audio
  security.rtkit.enable = true;

  # Disable PulseAudio
  services.pulseaudio.enable = false;

  # PipeWire configuration
  services.pipewire = {

    # Enable PipeWire
    enable = true;
    wireplumber.enable = true;

    # Enable other audio systems support
    alsa.enable = true;
    alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    pulse.enable = true;
    jack.enable = true;

  };

  # Allow packages to compile with PulseAudio support
  nixpkgs.config.pulseaudio = true;

}
