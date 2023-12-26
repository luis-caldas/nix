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

in {

  # The default imports for the system
  imports = [

    # First is Home Manager
    "${homeManager}/nixos"

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
