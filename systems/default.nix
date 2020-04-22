{

  # Boot
  boot = {
    timeout = 60;
    default = 0;
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
    desc = "bossu";
    groups = ["sudo"];
    pass = "functional";
    autologin = true;
  };

  # Extra set of packages that can be added easly
  # throught here
  # system = system wide; user = for user
  # normal = non graphical tools; video = gui tools and programs
  packages = {
    system = {
      normal = [];
      video = [];
    };
    user = {
      normal = [];
      video = [];
    };
  };

  # Base git configuration
  # Add the keys manually
  git = {
    name = "Luis";
    email = "admin@luiscaldas.com";
  };

  # Simple hostname config
  system = {
    # System hostname
    hostname = "unnamed";
    # System timezone
    timezone = "Europe/Dublin";
    # The mingetty message
    getty = {
      greeting = "Whenever there is a meeting, a parting is sure to follow. But that parting needs not last forever. Whether a parting be forever or merely for a short while... That is up to you.";
      help = "If you don't get that mask back soon, something terrible will happen!";
    };
    # The message of the day shown
    motd = "You've met with a terrible fate, haven't you?";
  };

  # Network basic config
  net = {
    interface = {
      main = "eth0";
    };
    id = "ffffffff";
  };

  # Services that should be turned on by default
  services = {
    ssh = false;
    docker = false;
  };

  # Should we initialize the graphical stuff
  graphical = false;

}
