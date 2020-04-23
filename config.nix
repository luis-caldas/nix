let

  # import library
  libr = (import <nixpkgs> {}).pkgs.lib;

  # Default path for the chosen system
  system-path = libr.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Import the chosen config file
  config-obj = libr.recursiveUpdate
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
