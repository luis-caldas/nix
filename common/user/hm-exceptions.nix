{ lib, config, pkgs, ... }:
{

  # Generate config for all packages
  options.exceptions = with lib; {
    unfree = mkOption {
      type = types.listOf types.string;
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
      "assaultcube"
      "steam" "steam-original" "steam-runtime" "steam-run"
      "minecraft-launcher"
      "dwarf-fortress"
      "reaper" "linuxsampler"
      "spotify" "spotify-unwrapped"
      "zoom"
      "unrar"
      "pycharm-professional" "webstorm" "clion"
    ]);

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [];

    # Home manager package overrides
    nixpkgs.config.packageOverrides = ogpkgs: (
      (config.exceptions.overrides ogpkgs)
      // {}
    );

  };

}
