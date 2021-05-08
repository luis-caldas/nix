args@{ lib, config, pkgs, utils, ... }:
let

  # My main config
  my = import ../config.nix { inherit lib; iso = true; };

  # Import the linker after configurations have been loaded
  linker = import ../linker.nix ( { inherit my; } // args );

in {

  imports = [

    linker

    # Import nixos iso channels
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>

    # Import nixos iso configurations
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

  ];

  # Override some of the iso configurations
  # So my ones may work on top
  networking.wireless.enable = false;
  services.mingetty.autologinUser = lib.mkForce null;
  # Boot loader configs should follow the iso
  boot.loader.timeout = lib.mkForce null;

}
