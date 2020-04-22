let

  # Default path for the chosen system
  system-path = "moon";

  # Import the chosen config file
  config-obj = import (./systems + ("/" + system-path) + "/config.nix");

in
{
  path = system-path;
  config = config-obj;
}
