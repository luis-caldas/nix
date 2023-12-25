{ my, mfunc, pkgs, ... }:
{

  # Enable rtkit for audio
  security.rtkit.enable = true;

  # Disable pulseaudio
  hardware.pulseaudio.enable = false;

  # Pipewire config
  services.pipewire = {

    # Enable pipewire
    enable = true;
    wireplumber.enable = true;

    # Enable other audio systems support
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

}
