{ pkgs, ... }:
let

  # Get list of directories in folder
  listDirs = folderName: 
    let 
      allNameList = pkgs.lib.mapAttrsToList (
        name: value:
          if (value == "directory") then
            name
          else
            ""
      ) (builtins.readDir folderName);
    in
      pkgs.lib.filter (
        name: name != ""
      ) allNameList;

  # List packages in folders
  stablePackages = listDirs ./.;

  # Create set of package names and calls
  packageSet = (
    pkgs.lib.genAttrs stablePackages (
      folderName: pkgs.lib.callPackageWith (pkgs // pkgs.python3Packages // packageSet) (./. + ("/" + folderName)) { }
    )
  );

in packageSet
