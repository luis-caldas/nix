{

  # useDefault -> Bool -> Any -> Any
  useDefault = should: default: nondefault:
    if should then
      default
    else
      nondefault;

  # Returns a list of the items inside a folder
  listFilesInFolder = libr: directorySource: libr.mapAttrsToList (name: value: name) (builtins.readDir directorySource);

  # Lists the contents of a folder and creates
  # their respective attributes
  listCreateLinks = libr: directorySource: directoryDest:
    let 
      listFiles = libr.mapAttrsToList (name: value: name) (builtins.readDir directorySource);
    in
    builtins.listToAttrs (
      map ( topName: {
        name = directoryDest + "/" + topName;
        value.source = directorySource + "/" + topName;
      }) listFiles
    );
}
