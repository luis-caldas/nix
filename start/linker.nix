{ lib, config, ... }:
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
    version = "0.4.3";
  in import (builtins.fetchTarball ({
    url = "https://github.com/nix-community/lanzaboote/archive/v${version}.tar.gz";
    sha256 = "sha256-If6vQ+KvtKs3ARBO9G3l+4wFSCYtRBrwX1z+I+B61wQ=";
  }));

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

  # Overlays
  nixpkgs.overlays = [ lanzaboote.overlays.default ];

  # Set Home Manager to use global Pkgs
  home-manager.useGlobalPkgs = true;

  # Import the files needed for the Home Manager package
  home-manager.users."${config.mine.user.name}" = { ... }: {

    # Default imports for Home Manager
    imports = lib.filesystem.listFilesRecursive ../common/manager;

  };

}
