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

      # Printing
      "brgenml1lpr"

      # Intel
      "intel-ocl"

      # Memtest
      "memtest86-efi"

      # Display
      "displaylink"
      "nvidia-x11" "nvidia-settings"

      # Browser
      "chromium" "chromium-unwrapped" "chrome-widevine-cdm"
      "ungoogled-chromium" "ungoogled-chromium-unwrapped"

      # Widevine
      "widevine-cdm"

      ################
      # Home Manager #
      ################

      # Games
      "assaultcube" "SpaceCadetPinball"
      "steam" "steam-original" "steam-runtime" "steam-run"
      "minecraft-launcher"
      "dwarf-fortress"
      "clonehero"
      "shipwright" (pkgs.unstable.shipwright.name)
      "sm64ex" "sm64ex-coop"
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
      "ciscoPacketTracer8"

      # Work
      "zoom"
      "vmware-horizon-client"
      "vmware-workstation"

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
