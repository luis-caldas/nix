{ lib, ... }:
let

  # Put all functions in attrset
  allFunctions = {

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

    # Function for safely reading a file
    safeReadFile = filePath:
      if (builtins.pathExists filePath) then
        lib.removeSuffix "\n" (builtins.readFile filePath)
      else
        "";

    # Concatenate without caring about types
    agnosticConcat = listInputs: let
      stringSeparator = "";
      concatSet = {
          "list" = builtins.concatLists;
          "string" = (listInput: builtins.concatStringsSep stringSeparator listInput);
          "set" = (listInput: builtins.foldl' lib.recursiveUpdate {} listInput);
          "none" = (listInput: {});
        };
      typesList = map builtins.typeOf listInputs;
      possibleList = builtins.attrNames concatSet;
      typeNow = let
        notFound = "none";
      in if (lib.all (x: builtins.elem x possibleList) typesList) &&
            ((lib.length typesList) > 0) then let
          first = builtins.head typesList;
        in if (lib.all (x: first == x) typesList) then
          first
        else notFound
      else notFound;
    in ((builtins.getAttr typeNow concatSet) listInputs);

    # Function to insert new attrs in overrides
    overrideInsert = oldAttrs: newAttrs: let
      mergeIfNeeded = newName: newValue:
        if (builtins.hasAttr newName oldAttrs) then
          agnosticConcat [ newValue (builtins.getAttr newName oldAttrs) ]
        else
          newValue;
      mergedAttrs = lib.mapAttrsToList (name: value: { inherit name; value = mergeIfNeeded name value; }) newAttrs;
    in
      builtins.listToAttrs mergedAttrs;

  };

in allFunctions
