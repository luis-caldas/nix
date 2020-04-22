{

  # Config
  version = "19.09";

  # Name of the folder inside the hardware folder containing the
  # system's hardware configuration
  # normally generated on install
  hardware = {
    folder = "moon";
    # Should we use the custom monitor configuration that
    # is located with the hardware
    cmonitor = true;
  };

  # Boot
  boot = {
    timeout = 1;
    default = 2;
    efi = true;
    device = "nodev";
  };

  # Extra kernel parameters to be passed
  kernel = {
    params = [];
  };

  # Overall user naming
  user = {
    name = "majora";
    desc = "Bossu Desu";
    groups = ["sudo"];
    pass = "functional";
  };

  # Base git configuration
  # Add the keys manually
  git = {
    name = "Luis";
    email = "admin@luiscaldas.com";
  };

  system = {
    # System hostname
    hostname = "moon";
    # The message of the day shown
    motd = "You've met with a terrible fate, haven't you?";
    # System timezone
    timezone = "Europe/Dublin";
  };

  # Network basic config
  net = {
    interface = {
      main = "enp4s0";
    };
    id = "19709431";
  };

  # Services that should be turned on by default
  services = {
    ssh = true;
    docker = false;
  };

  # Should we initialize the graphical stuff
  graphical = true;

}
