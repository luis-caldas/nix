let

  # Default path for the chosen system

  system-path = "box";

  #####

  # Import the chosen config file
  config-obj = (import <nixpkgs> {}).pkgs.lib.recursiveUpdate
    (import (./systems + "/default.nix"))
    (import (./systems + ("/" + system-path) + "/config.nix"));

in
{
  path = system-path;
  config = config-obj;
}
