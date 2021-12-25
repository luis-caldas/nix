args@{ pkgs, mpkgs, lib, ... }:
let

  # Get list of files in folder
  listDirs = folderName:
    let
      allNameList = lib.mapAttrsToList (
        name: value:
          if (value == "directory") then
            name
          else
            ""
      ) (builtins.readDir folderName);
    in
      lib.filter (
        name: name != ""
      ) allNameList;

  # List packages in folders
  optionFiles = map (folderName: import (./options + ("/" + folderName)) args) (listDirs ./options);

in {

  imports = optionFiles;

}
