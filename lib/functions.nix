{ pkgs, lib, ... }:
let

  allFunctions = rec {

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

    listAllSuffixFilesClean = directoryPath: extension:
      filterFilesExtension (builtins.readDir directoryPath) extension;

    listAllSuffixFilesRecursive = directoryPath: extension:
      filterFilesExtension (lib.filesystem.listFilesRecursive directoryPath) extension;

    listFileNamesExtensionExcluded = path: excluded: extension: let

      # Get all the files to load
      allImportable = listAllSuffixFilesClean path extension;

      # Remove all extensions and path
      allFileNames = map (file: lib.strings.removeSuffix ".${extension}" file) allImportable;

      # Remove unwanted files
      allCleanFileNames = builtins.filter (file: !(builtins.elem file excluded)) allFileNames;

    in
      allCleanFileNames;

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

    # Get last with separator
    getLastDash = inputString:
      lib.lists.last (lib.strings.splitString "-" inputString);

    # Generates SSL Key and Certificate
    generateUnsafeSSL = let
      duration = 365 * 10;
      names = {
        key = "key";
        cert = "cert";
      };
    in
      pkgs.runCommand "ssl-generated"
        { buildInputs = [ pkgs.openssl ]; } ''
          mkdir -p $out
          openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days ${builtins.toString duration} -nodes \
            -keyout $out/${names.key} -out $out/${names.cert} \
            -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"
        '';

  };

in {

  # Overlay for all the functions
  nixpkgs.overlays = [

    # The overlay
    (final: prev: let

      # Name of the attribute we are getting into
      attrName = "functions";

      # Our current functions
      current = allFunctions;

    in {

    # The functions
    "${attrName}" = if builtins.hasAttr attrName prev then (prev."${attrName}" // current) else current;

    })

  ];

}