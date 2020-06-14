{ lib, ... }:
let

  # useDefault -> Bool -> Any -> Any
  useDefault = should: default: nondefault:
    if should then
      default
    else
      nondefault;

  # Returns a list of the items inside a folder
  listFilesInFolder = directorySource: lib.mapAttrsToList (name: value: name) (builtins.readDir directorySource);

  # Returns a list of the items inside a folder with the full path
  listFullFilesInFolder = directorySource: map (strin: directorySource + ("/" + strin)) (listFilesInFolder directorySource);

  # Lists the contents of a folder and creates
  # their respective attributes
  listCreateLinks = directorySource: directoryDest:
    let
      listFiles = listFilesInFolder directorySource;
    in
    builtins.listToAttrs (
      map ( topName: {
        name = directoryDest + "/" + topName;
        value.source = directorySource + "/" + topName;
      }) listFiles
    );

in {
  useDefault = useDefault;
  listFilesInFolder = listFilesInFolder;
  listFullFilesInFolder = listFullFilesInFolder;
  listCreateLinks = listCreateLinks;
}
