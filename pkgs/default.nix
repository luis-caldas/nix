{ lib, pkgs, ... }:

let

  # Get list of directories in a folder
  listDirs = folderPath:
    if builtins.pathExists folderPath then
      builtins.sort (left: right: left < right) (
        builtins.attrNames (
          lib.attrsets.filterAttrs
            (_: value: value == "directory")
            (builtins.readDir folderPath)
        )
      )
    else
      [];

  # Get all packages in a folder using the given package scope
  packageFiles = folderPath: packageScope:
    lib.genAttrs (listDirs folderPath) (
      folderName: lib.callPackageWith packageScope (folderPath + "/${folderName}") {}
    );

  # Get all option files in a directory
  optionFiles = folderPath:
    map (folderName: folderPath + "/${folderName}") (listDirs folderPath);

  # Folders
  folders = {
    stable = ./stable;
    unstable = ./unstable;
    options = ./options;
  };

  # Package scopes
  packagesStable = pkgs // stablePackages;
  packagesUnstable = (pkgs.unstable or {}) // unstablePackages;

  # Create sets of package names and calls
  stablePackages = packageFiles folders.stable packagesStable;
  unstablePackages = packageFiles folders.unstable packagesUnstable;

  # Get all the possible options
  options = optionFiles folders.options;

  # Join all packages into a single attribute set
  # Stable packages go at the top level and unstable packages get their own attribute
  packages = stablePackages // { unstable = unstablePackages; };

in {

  # Import all the possible options
  imports = options;

  # Create an overlay with all our packages
  nixpkgs.overlays = [
    (_final: _prev: {
      custom = packages;
    })
  ];

}
