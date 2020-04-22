{

  # Boot
  boot = {
    timeout = 4;
    default = 0;
    efi = false;
    device = "/dev/sda";
  };

  # Extra kernel parameters to be passed
  kernel = {
    params = ["vga=normal" "nomodeset"];
  };

  # Overall user naming
  user = {
    name = "majora";
    desc = "Bossu Desu";
    groups = ["docker"];
    pass = "functional";
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

  system = {
    # System hostname
    hostname = "box";
    # The message of the day shown
    motd = "You've met with a terrible fate, haven't you?";
    # System timezone
    timezone = "Europe/Dublin";
  };

  # Network basic config
  net = {
    interface = {
      main = "enp3s0";
    };
    id = "19719431";
  };

  # Services that should be turned on by default
  services = {
    ssh = true;
    docker = true;
  };

  # Should we initialize the graphical stuff
  graphical = false;

}
