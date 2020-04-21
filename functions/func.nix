{

  # useDefault -> Bool -> Any -> Any
  useDefault = should: default: nondefault:
    if should then
      default
    else
      nondefault;

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
