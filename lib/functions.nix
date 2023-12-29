{ lib, ... }:

let

  # Put all functions in attrset
  allFunctions = rec {

    # Returns a list of the items inside a folder
    listFilesInFolder = directorySource: lib.mapAttrsToList (name: value: name) (builtins.readDir directorySource);

    # Lists the contents of a folder and creates
    # a valid link for home manager
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

    # Filters a list of file based on suffix
    filterFilesExtension = listFiles: extension:
      lib.attrsets.filterAttrs
      (name: value: value == "regular" && lib.strings.hasSuffix ".${extension}" name)
      listFiles;

    listAllSuffixFiles = directoryPath: extension:
      filterFilesExtension extension (builtins.readDir directoryPath);

    listAllSuffixFilesReucsive = directoryPath: extension:
      filterFilesExtension extension (lib.filesystem.listFilesRecursive directoryPath);

    # Capitalises first and anything after a space
    capitaliseString = inputString: let
        splitChar = " ";
        listStrings = lib.strings.splitString splitChar inputString;
        capitalisedList = map (eachWord: let
            splitWord = lib.strings.stringToCharacters eachWord;
            firstChar = builtins.head splitWord;
            restString = lib.strings.concatStrings (lib.lists.drop 1 splitWord);
            newWord = (lib.strings.toUpper firstChar) + restString;
          in newWord) listStrings;
        properName = lib.strings.concatStringsSep splitChar capitalisedList;
      in properName;

  };

in {

  # The functions to the overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # All the functions
      functions = allFunctions;

    })

  ];


}
