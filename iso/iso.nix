args@{ lib, config, pkgs, utils, ... }:
let

  # My main config
  my = import ../config.nix { inherit lib pkgs; iso = true; };

  # Import the linker after configurations have been loaded
  linker = import ../linker.nix ( { inherit my; } // args );

in {

  imports = [

    linker

    # Import nixos iso channels
    <nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix>

  ];

  # EFI and USB booting
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # Override some of the iso configurations
  # So my ones may work on top
  networking.wireless.enable = false;
  # Boot loader configs should follow the iso
  boot.loader.timeout = lib.mkForce null;

}
