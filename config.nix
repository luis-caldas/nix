let

  # Default path for the chosen system

  system-path = "box";

  #####

  # Import the chosen config file
  config-obj = (import <nixpkgs> {}).pkgs.lib.recursiveUpdate
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
