{ lib, config, pkgs, ... }:
{

  # Generate config for all packages
  options.exceptions = with lib; {
    unfree = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    overrides = mkOption {
      type = types.functionTo types.attrs;
      default = n: {};
    };
  };

  # General config
  config = {

    # Allow unfree stuff
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (
      config.exceptions.unfree
    ++ [
      "assaultcube" "SpaceCadetPinball"
      "steam" "steam-original" "steam-runtime" "steam-run"
      "minecraft-launcher"
      "dwarf-fortress"
      "davinci-resolve"
      "reaper" "linuxsampler"
      "spotify" "spotify-unwrapped"
      "zoom" "discord"
      "android-sdk-tools"
      "pycharm-professional" "webstorm" "clion" "datagrip" "idea-ultimate"
      "ciscoPacketTracer8"
    ]);

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [
      pkgs.python2.name  # Davinci Resolve
    ];

    # Home manager package overrides
    nixpkgs.config.packageOverrides = ogpkgs: (
      (config.exceptions.overrides ogpkgs)
      // {

      }
    );

  };

}
