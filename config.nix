{ lib, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  path-file = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Check if it is a iso and set the correct path then
  system-path = if iso then
    "iso"
  else
    path-file;

  # Import the chosen config file
  config-obj = lib.recursiveUpdate
    (builtins.fromJSON (
       builtins.readFile (./config + "/default.json"))
    )
    (builtins.fromJSON (
       builtins.readFile (./config + ("/" + system-path) + "/config.json"))
    );

  # Import the firefox config
  firefox-obj = builtins.fromJSON (builtins.readFile (./config + "/firefox.json"));

in
{
  path = system-path;
  config = config-obj;
  firefox = firefox-obj;
}
