{ lib, ... }:
let

  # Default path for the chosen system
  system-path = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Import the chosen config file
  config-obj = lib.recursiveUpdate
    (builtins.fromJSON (
       builtins.readFile (./config + "/default.json"))
    )
    (builtins.fromJSON (
       builtins.readFile (./config + ("/" + system-path) + "/config.json"))
    );

in
{
  path = system-path;
  config = config-obj;
}
