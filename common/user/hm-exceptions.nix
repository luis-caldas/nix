{ lib, config, ... }:
{

  # Generate config for all packages
  options.exceptions = with lib; {
    unfree = mkOption {
      type = types.listOf types.string;
      default = [];
    };
    overrides = mkOption {
      type = types.attrsOf types.package;
      default = {};
    };
  };

  # General config
  config = {

    # Allow unfree stuff
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (
      config.exceptions.unfree
    ++ [
      "assaultcube"
      "steam" "steam-original" "steam-runtime"
      "minecraft-launcher"
      "dwarf-fortress"
      "reaper" "linuxsampler"
      "spotify" "spotify-unwrapped"
      "unrar"
    ]);

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.0.2u"
    ];

    # Home manager package overrides
    nixpkgs.config.packageOverrides = pkgs: (
      (config.exceptions.overrides pkgs)
      // {
      # Add custom file to flightgear data
      flightgear = pkgs.flightgear.overrideAttrs (oldAttrs: {
        data = oldAttrs.data.overrideAttrs (dataOldAttrs: let
          headTrackFile = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/opentrack/opentrack/opentrack-2022.1.1/contrib/FlightGear/Protocol/headtracker.xml";
            sha256 = "0airpy02jsq87d1vwsiwfxkgkyinlinvwq4rghb8d4h0yjmw7kdw";
          };
        in {
          pname = dataOldAttrs.pname + "-custom";
          installPhase = (if (builtins.hasAttr "installPhase" dataOldAttrs) then dataOldAttrs.installPhase else "") + ''
            cp "${headTrackFile}" $out/share/FlightGear/Protocol/headtrack.xml
          '';
        });
      });
    });

  };

}
