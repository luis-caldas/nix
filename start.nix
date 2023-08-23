args@{ lib, config, pkgs, utils, stdenv, ... }:
let

  # My main config
  my = import ./config.nix { inherit lib pkgs config; iso = false; };

  # Import the linker after configurations have been loaded
  linker = import ./linker.nix ( { inherit my; } // args );

in {

  # Add the system import list
  imports = [ linker ];

}
