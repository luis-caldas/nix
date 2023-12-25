{ ... }:
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

  # Important paths
  

in {

  # The default imports for the system
  imports = [

    # First is Home Manager
    "${home-manager}/nixos"

  ];

  # Import the files needed for the Home Manager package
  home-manager.users."${my.config.user.name}" = { ... }: {

    # Default imports for Home Manager
    imports = [];

  };

}
