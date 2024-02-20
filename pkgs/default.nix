{ lib, pkgs, ... }:

let

  # Get list of directories in folder
  listDirs = folderPath:
    builtins.attrNames (
      lib.attrsets.filterAttrs
      (name: value: value == "directory")
      (builtins.readDir folderPath)
    );

  # Gets all the packages in the folder
  # Using a giving set of packages
  packageFiles = folderPath: packages:
    lib.genAttrs (listDirs folderPath) (
      folderName: lib.callPackageWith packages (folderPath + ("/" + folderName)) { }
    );

  # Gets all the option files in a directory
  optionFiles = givenFolder:
    map
    (folderName: givenFolder + ("/" + folderName))
    (listDirs givenFolder);


  # Folders
  folders = {
    stable = ./stable;
    unstable = ./unstable;
    options = ./options;
  };

  # Concoction of packages
  packagesStable = (pkgs // stablePackages);
  packagesUnstable = (pkgs.unstable // unstablePackages);

  # Create set of package names and calls
  stablePackages = packageFiles folders.stable packagesStable;
  unstablePackages = packageFiles folders.unstable packagesUnstable;

  # Get all the possible options
  options = optionFiles folders.options;

  # Join all the packages into single attr set
  # Stable goes on top level and unstable on its own sub attr
  packages = stablePackages //
  # Unstable has its own sub attr
  { unstable = unstablePackages; };

in {

  # Import all the possible options
  imports = options;

  # Create an overlay with all our packages
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # The new attribute with all the new packages
      custom = packages;

    })

  ];

}
