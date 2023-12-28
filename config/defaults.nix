{ lib, ... }:
{

  # My general configurations for the system
  options.mine = with lib; with types; {

    # The boot options be it MBR GRUB or EFI
    boot = {

      efi = mkOption {
        description = "Use EFI for boot";
        type = bool;
        default = true;
      };

      grub = mkOption {
        description = "Use GRUB for boot, otherwise systemd-boot is used";
        type = bool;
        default = false;
      };

      timeout = mkOption {
        description = "Timeout for the boot entry selection";
        type = int;
        default = 1;
      };

      default = mkOption {
        description = "Default entry to be picked when using GRUB";
        type = int;
        default = 0;
      };

      devices = mkOption {
        description = "Device to install MBR GRUB onto";
        type = listOf str;
        default = [ "nodev" ];
      };

      prober = mkOption {
        description = "Probe the disks for OSs on GRUB";
        type = bool;
        default = false;
      };

      tune = mkOption {
        description = "Play tune on GRUB";
        type = bool;
        default = false;
      };

      top = mkOption {
        description = "Initilise `top` on TTY8";
        type = bool;
        default = false;
      };

      override = mkOption {
        description = "Do not configure boot";
        type = bool;
        default = false;
      };

    };

    # Kernel specific options
    kernel = {

      text = mkOption {
        description = "Extra text mode for the systems";
        type = bool;
        default = true;
      };

      params = mkOption {
        description = "Extra parameters for the kernel line on boot";
        type = listOf str;
        default = [];
      };

    };

    # User configuration
    user = {

      name = mkOption {
        description = "Name of the main user";
        type = str;
        default = "lu";
      };

      uid = mkOption {
        description = "User ID of the main user";
        type = int;
        default = 1000;
      };

      gid = mkOption {
        description = "Group ID of the main users group";
        type = int;
        default = 1000;
      };

      desc = mkOption {
        description = "Description / GECOS / Full Name";
        type = str;
        default = "Luis";
      };

      groups = mkOption {
        description = "Extra groups for the user";
        type = listOf str;
        default = [];
      };

      admin = mkOption {
        description = "Enable `sudo` command for user";
        type = bool;
        default = true;
      };

      pass = mkOption {
        description = "Default password for the user";
        type = str;
        default = "functional";
      };

      autologin = mkOption {
        description = "Enable TTY autologin for the user";
        type = bool;
        default = false;
      };

      # Git configuration
      git = {

        name = mkOption {
          description = "Name shown for `git`";
          type = str;
          default = "Luis";
        };

        email = mkOption {
          description = "Email shown for `git`";
          type = str;
          default = "luis@caldas.ie";
        };

      };

    };

    # System configuration
    system = {

      hostname = mkOption {
        description = "Hostname for this system";
        type = str;
        default = "forgotten";
      };

      timezone = mkOption {
        description = "Timezone for the system";
        type = str;
        default = "Europe/Dublin";
      };

      locale = mkOption {
        description = "System locale";
        type = str;
        default = "en_IE.UTF-8";
      };

      layout = lib.mkOption {
        description = "Preferred keyboard layouts in order";
        type = listOf str;
        default = [ "ie" "us" ];
      };

      # The general location of the closest airport
      location = {

        latitude = mkOption {
          description = "Positional latitude";
          type = float;
          default = 53.3498;
        };

        longitude = mkOption {
          description = "Positional longitude";
          type = float;
          default = -6.2603;
        };

      };

      # Greeting messages for the TTY
      getty = {

        greeting = mkOption {
          description = "The greeting message on TTY login";
          type = str;
          default = "\\S{PRETTY_NAME} @ \\r \\m \\b \\l\nSystem initiated successfully";
        };

        help = mkOption {
          description = "The help message on TTY login";
          type = str;
          default = "You shouldn't need help at this point";
        };

      };

      motd = mkOption {
        description = "The message of the day";
        type = str;
        default = "Welcome back";
      };

    };

    # General networking options
    network = {

      # MAC configurations for NetworkManager
      mac = mkOption {
        description = "How to set MAC addresses";
        type = str;
        default = "stable";
      };

      # Firewall options
      firewall = {

        enable = mkEnableOption "Firewall";

        ping = mkEnableOption "ICMP Replies";

      };

    };

    # All the services for the system
    services = {

      ssh = mkEnableOption "SSH Service";

      avahi = mkEnableOption "Avahi";

      docker = mkEnableOption "docker";

      printing = mkEnableOption "CUPS";

      # Virtualisation configuration
      virtual = {

        enable = mkEnableOption "libvirt";

        swtpm = mkEnableOption "TPM Emulation";

      };

    };

    # All the graphical configurations
    graphics = {

      enable = mkEnableOption "Graphical Inteface";

      numlock = mkOption {
        description = "Startup system with NumLock enabled";
        type = bool;
        default = true;
      };

      cursor = mkOption {
        description = "Name of the default cursor used";
        type = str;
        default = "hacked-grey-hd";
      };

      icon = mkOption {
        description = "Name of the preferred icon theme to use";
        type = str;
        default = "Papirus-Dark";
      };

      theme = mkOption {
        description = "Name of the preferred system theme to use";
        type = str;
        default = "Adwaita-dark";
      };

    };

    # All software packages for specific tasks
    production = {

       audio = mkEnableOption "Audio Production Software";

       video = mkEnableOption "Video Production Software";

       models = mkEnableOption "3D Modelling Software";

       software = mkEnableOption "Software Development";

       business = mkEnableOption "Professional Productivity Software";

       electronics = mkEnableOption "Electronics Design";

    };

    # Chromium configuration
    browser = {

      policies = mkOption {
        description = "Extra policies to add to the default chromium installations";
        type = attrs;
        default = {};
      };

      # Extension hashes for different chromium types
      extensions = {

        common = mkOption {
          description = "Extensions for all the installations";
          type = listOf str;
          default = [
            "padekgcemlokbadohgkifijomclgjgif" # switchy proxy omega
            "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
            "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
            "fnaicdffflnofjppbagibeoednhnbjhg" # floccus bookmarks manager
            "cnojnbdhbhnkbcieeekonklommdnndci" # search by image
            "gbmdgpbipfallnflgajpaliibnhdgobh" # json viewer
            "nngceckbapebfimnlniiiahkandclblb" # bitwarden client
            "hkgfoiooedgoejojocmhlaklaeopbecg" # picture in picture
          ];
        };

        others = mkOption {
          description = "Extensions for specific installations";
          type = attrs;
          default = {

            # The main installation
            main = {
              path = "chromium";
              key = "N";
              extensions = [
                "bjilljlpencdcpihofiobpnfgcakfdbe" # clear browsing data
              ];
            };

            # The persistent installation
            persistent = {
              path = "chromium-persistent";
              key = "M";
              extensions = [];
            };

            # The unchanged installation
            normal = {
              path = "chromium-normal";
              key = "B";
              extensions = [];
            };

          };
        };

      };

    };

    # Whether to make the system minimal
    # Less stuff to download and install
    minimal = mkEnableOption "Minimal System";

    # Memory compression
    zram = mkEnableOption "ZRAM";

    # Enable all the games
    games = mkEnableOption "Games";

    # Enable LaTeX
    tex = mkEnableOption "LaTeX";

    # Enable audio
    audio = mkEnableOption "Audio";

    # Enable bluetooth
    bluetooth = mkEnableOption "Bluetooth";

  };

}
