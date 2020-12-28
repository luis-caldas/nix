{ pkgs, upkgs, ... }:

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
  stablePackages = listDirs ./stable;
  unstablePackages = listDirs ./unstable;

  # create set of package names and calls
  packageSet = (
    pkgs.lib.genAttrs stablePackages (
      folderName: pkgs.lib.callPackageWith pkgs (./stable + ("/" + folderName)) { }
    )
  ) // (
    pkgs.lib.genAttrs unstablePackages (
      folderName: pkgs.lib.callPackageWith upkgs (./unstable + ("/" + folderName)) { }
    )
  );

  # Manally reassign some of the names
  manualNames = {
    srb2 = packageSet.srb2full.srb2;
  };

  # Set this object to be the package set
  self = packageSet // manualNames;

in self
