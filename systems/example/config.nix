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
    name = "user";
    desc = "Example User";
    groups = ["sudo" "exemple"];
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
    name = "Name";
    email = "some@email.com";
  };

  system = {
    # System hostname
    hostname = "hoster";
    # The message of the day shown
    motd = "Example motd";
    # System timezone
    timezone = "Europe/Dublin";
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
