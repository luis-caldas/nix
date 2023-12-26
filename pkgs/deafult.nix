{ lib, pkgs, ... }:

let

  # Folders
  packagesFolder = ./all;
  optionsFolder = ./options;

  # Get list of directories in folder
  listDirs = folderPath:
    builtins.attrNames (lib.attrsets.filterAttrs (name: value: value == "directory") (builtins.readDir folderPath));

  # All the packages
  allPackages = listDirs packagesFolder;

  # Create set of package names and calls
  packageSet = (
    lib.genAttrs stablePackages (
      folderName: lib.callPackageWith pkgs (packagesFolder + ("/" + folderName)) { }
    )
  );

  # Manally reassign some of the names
  manualNames = {
    srb2 = packageSet.srb2.srb2;
    srb2kart = packageSet.srb2kart.srb2kart;
  };

  # Create the all emcompassing object of packages
  entirePackages = packageSet // manualNames;

  # Get all the possible options
  optionFiles = map (folderName: optionsFolder + ("/" + folderName)) (listDirs optionsFolder);

in {

  # Import all the possible options
  imports = optionFiles;

  # Create an overlay with all our packages
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # The new attribute with all the new packages
      custom = entirePackages;

    })

  ];

}
