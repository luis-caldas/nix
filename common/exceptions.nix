{ pkgs, lib, config, ... }:
{

  # Generate config for all packages
  options.exceptions = with lib; {

    # Add unfree exceptions on the fly
    unfree = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    # Add overrides on the fly
    overrides = mkOption {
      type = types.functionTo types.attrs;
      default = input: {};
    };

  };

  # General config
  config = {

    # Allow unfree stuff
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (
      config.exceptions.unfree
    ++ [

      ###########
      # General #
      ###########

      # Browser
      "chromium" "chromium-unwrapped" "widevine-cdm"

      # Printing
      "brgenml1lpr"

      # Intel
      "intel-ocl"

      # Memtest
      "memtest86-efi"

      # Display
      "displaylink"
      "nvidia-x11" "nvidia-settings"

      ################
      # Home Manager #
      ################

      # Games
      "assaultcube" "SpaceCadetPinball"
      "steam" "steam-unwrapped" "steam-original" "steam-runtime" "steam-run"
      "minecraft-launcher"
      "dwarf-fortress"
      "clonehero"
      "shipwright" "2ship2harkinian"
      "sm64ex" "sm64coopdx"
      "libretro-snes9x"

      # Production
      "davinci-resolve"
      "reaper" "linuxsampler"

      # Music
      "spotify" "spotify-unwrapped"

      # Social
      "discord"

      # Android
      "android-sdk-tools"

      # Software Development
      "pycharm-professional" "webstorm" "clion" "datagrip" "idea-ultimate"
      "ciscoPacketTracer8" "winbox"
      "volatility3"
      "drawio"

      # Work
      "zoom"
      "vmware-horizon-client"
      "vmware-workstation"

      # Fonts
      "corefonts" "vista-fonts"

      # System
      "unrar"

    ]);

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [

      # For Davinci Resolve
      pkgs.python2.name

    ];

    # Overrides
    nixpkgs.config.packageOverrides = ogpkgs: (
      (config.exceptions.overrides ogpkgs)
      // {}
    );

  };

}
