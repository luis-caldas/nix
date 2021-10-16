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

  # Function to find the index of a element in the list
  getFirstIndex = nameElement: listInput:
    let
      genListIndexes = builtins.genList (x: x) (builtins.length listInput);
      foundIndex = lib.findFirst (x: nameElement == (lib.elemAt listInput x)) 0 genListIndexes;
    in
    foundIndex;

  # Function to get the element from a Xresources file
  getElementXRes = fileIn: elemString:
  let
    # Acquire the Xresources file
    xreFile = builtins.readFile fileIn;
    # Create a list with the items
    xreList = lib.remove "" (lib.splitString " " (builtins.replaceStrings ["\n"] [" "] xreFile));
  in
  # Extract value after on list
    lib.elemAt xreList ((getFirstIndex elemString xreList) + 1);

in {
  useDefault = useDefault;
  listFilesInFolder = listFilesInFolder;
  listFullFilesInFolder = listFullFilesInFolder;
  listCreateLinks = listCreateLinks;
  getFirstIndex = getFirstIndex;
  getElementXRes = getElementXRes;
}
