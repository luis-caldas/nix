{ lib, pkgs, mpkgs, my, config, ... }:
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
      "brgenml1lpr"
      "intel-ocl"
      "memtest86-efi"
      "displaylink"
      "nvidia-x11" "nvidia-settings"
    ]);

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [];

    # Overrides
    nixpkgs.config.packageOverrides = ogpkgs: (
      (config.exceptions.overrides ogpkgs)
      // {}
    );

  };

}
