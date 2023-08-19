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

  # Set up bluetooth codecs for wireplumber
  environment.etc = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
      bluez_monitor.properties = {
        ["bluez5.enable-sbc-xq"] = true,
        ["bluez5.enable-msbc"] = true,
        ["bluez5.enable-hw-volume"] = true,
        ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
      }
    '';
  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

}
