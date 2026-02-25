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

      # Ventoy
      "ventoy"

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
      "pycharm" "webstorm" "clion" "datagrip" "idea" "rust-rover"
      "winbox"
      "volatility3"
      "drawio"

      # Work
      "zoom"
      "omnissa-horizon-client"
      "vmware-workstation"

      # Fonts
      "corefonts" "vista-fonts"

      # Office
      "aspell-dict-en-science"

      # System
      "unrar"

    ]);

    # !!!!!!!!!!!!!! #
    # Unsafe Section #
    # !!!!!!!!!!!!!! #

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [

      # BUG Unsafe

      # For Davinci Resolve
      pkgs.python2.name

      # For ESPHome, John & Scapy
      pkgs.python3Packages.ecdsa.name

      # For Dolphin, Dislocker & RetroArch
      pkgs.mbedtls_2.name

      # JDK & Switch USB Loader
      pkgs.gradle_7.name

      # Ventoy
      pkgs.ventoy.name

    ];

    # Overrides
    nixpkgs.config.packageOverrides = ogpkgs: (
      (config.exceptions.overrides ogpkgs)
      // {}
    );

  };

}
