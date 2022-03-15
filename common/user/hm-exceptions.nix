{ lib, ... }:
{

  # Allow unfree stuff
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "assaultcube"
    "steam" "steam-original" "steam-runtime"
    "minecraft-launcher"
    "dwarf-fortress"
    "reaper" "linuxsampler"
    "unrar"
  ];

  # Allow some insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.0.2u"
  ];

}