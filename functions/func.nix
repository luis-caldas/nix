{

  # useDefault -> Bool -> Any -> Any
  useDefault = should: default: nondefault:
    if should then
      default
    else
      nondefault;

  # Returns a list of the items inside a folder
  listFilesInFolder = libr: directorySource: libr.mapAttrsToList (name: value: name) (builtins.readDir directorySource);

  # Returns a list of the items inside a folder with the full path
  listFullFilesInFolder = mfuns: libr: directorySource: map (strin: directorySource + ("/" + strin)) (mfuns.listFilesInFolder libr directorySource);

  # Lists the contents of a folder and creates
  # their respective attributes
  listCreateLinks = mfuns: libr: directorySource: directoryDest:
    let 
      listFiles = mfuns.listFilesInFolder libr directorySource;
    in
    builtins.listToAttrs (
      map ( topName: {
        name = directoryDest + "/" + topName;
        value.source = directorySource + "/" + topName;
      }) listFiles
    );

  # Checks if a file exists and if so return its contents

}
