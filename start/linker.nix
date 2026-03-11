{ lib, config, pkgs, ... }:
let

  # Extract this version from NixPkgs
  version = let
    versionList = lib.splitString "." lib.version;
  in builtins.elemAt versionList 0 +
    "." +
    builtins.elemAt versionList 1;

  # Home manager
  homeManager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    ref = "release-" + version;
  };

  # Lanzaboote
  lanzaboote = let
    version = "1.0.0";
  in import (builtins.fetchTarball ({
    url = "https://github.com/nix-community/lanzaboote/archive/v${version}.tar.gz";
    sha256 = "sha256:17srvx92f0xymayfislm5d87bjd6n1p80s350my8si737iaa16a4";
  })) { inherit pkgs; };

in {

  # The default imports for the system
  imports = [

    # First is Home Manager
    "${homeManager}/nixos"

    # Lanzaboote
    lanzaboote.nixosModules.lanzaboote

    # Exceptions
    ../common/exceptions.nix

  ]
  # All the remaining files
  ++ (lib.filesystem.listFilesRecursive ../common/main);

  # Set Home Manager to use global Pkgs
  home-manager.useGlobalPkgs = true;

  # Import the files needed for the Home Manager package
  home-manager.users."${config.mine.user.name}" = { ... }: {

    # Default imports for Home Manager
    imports = lib.filesystem.listFilesRecursive ../common/manager;

  };

}
