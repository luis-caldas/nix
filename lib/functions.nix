{ lib, ... }:
rec {

  # Returns a list of the items inside a folder
  listFilesInFolder = directorySource: builtins.attrNames (builtins.readDir directorySource);

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

  # List the regular files
  listRegularFiles = directory: (builtins.attrNames (
    lib.attrsets.filterAttrs
    (name: value: value == "regular")
    (builtins.readDir directory)
  ));

  # Filters a list of file based on suffix
  filterFilesExtension = listFiles: extension:
    builtins.attrNames
      (lib.attrsets.filterAttrs
      (name: value: value == "regular" && lib.strings.hasSuffix ".${extension}" name)
      listFiles);

  listAllSuffixFiles = directoryPath: extension:
    map (each: "${directoryPath}/${each}") (filterFilesExtension (builtins.readDir directoryPath) extension);

  listAllSuffixFilesRecursive = directoryPath: extension:
    filterFilesExtension (lib.filesystem.listFilesRecursive directoryPath) extension;

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


  # Function for safely reading a file
  safeReadFile = filePath:
    if (builtins.pathExists filePath) then
      lib.removeSuffix "\n" (builtins.readFile filePath)
    else
      "";

}