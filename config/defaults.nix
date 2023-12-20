{ lib, ... }:
{

  # My general configurations for the system
  options.my.config = with lib; with type; {

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
        default = 60;
      };

      default = mkOption {
        description = "Default entry to be picked when using GRUB";
        type = int;
        default = 0;
      };

      device = mkOption {
        description = "Device to install MBR GRUB onto";
        type = str;
        default = "nodev";
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

      params = mkOptions {
        description = "Extra parameters for the kernel line on boot";
        type = listOf str;
        default = [];
      };

    };

    # User configuration
    user = {

      name = mkOptions {
        description = "Name of the main user";
        type = str;
        default = "lu";
      };

      uid = mkOptions {
        description = "User ID of the main user";
        type = int;
        default = 1000;
      };

      gid = mkOptions {
        description = "Group ID of the main users group";
        type = int;
        default = 1000;
      };

      desc = mkOptions {
        description = "Description / GECOS / Full Name";
        type = str;
        default = "Luis";
      };

      groups = mkOptions {
        description = "Extra groups for the user";
        type = listOf str;
        default = [];
      };

      admin = mkOptions {
        description = "Enable `sudo` command for user";
        type = bool;
        default = true;
      };

      pass = mkOptions {
        description = "Default password for the user";
        type = str;
        default = "functional";
      };

      autologin = mkOptions {
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

        latitude = mkOptions {
          description = "Positional latitude";
          type = float;
          default = 53.3498;
        };

        longitude = mkOptions {
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

      motd = mkOptions {
        description = "The message of the day";
        type = str;
        default = "Welcome back";
      };

    };

    # General networking options
    network = {

      # MAC configurations for NetworkManager
      mac = {

        cable = mkOption {
          description = "MAC address of the ethernet interface";
          type = str;
          default = "stable";
        };

        wifi = mkOption {
          description = "MAC address of the wifi interface";
          type = str;
          default = "stable";
        };

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
      virt = {

        enable = mkEnableOption "libvirt";

        swtpm = mkEnableOption "TPM Emulation";

      };

      # Startup custom scripts
      startup = {

        permit = mkOption {
          description = "List of files to make permissible to the default user at startup";
          type = listOf str;
          default = [];
        };

        create = mkOption {
          description = "List of files to create at startup";
          type = listOf str;
          default = [];
        };

        start = mkOption {
          description = "List of scripts to run at startup";
          type = listOf str;
          default = [];
        };

      };

    };

    # All the graphical configurations
    graphical = {

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
        default = "Adwaita-Dark";
      };

    };

    # Chromium configuration
    chromium = {

      policies = mkOption {
        description = "Extra policies to add to the default chromium installations";
        type = attrs;
        default = {};
      };

      # Extension hashes for different chromium types
      extensions = {

        common = mkOption {
          description = "Extensions for the common installation";
          type = listOf str;
          default = [];
        };

        main = mkOption {
          description = "Extensions for the main installation";
          type = listOf str;
          default = [];
        };

        persistent = mkOption {
          description = "Extensions for the persistent installation";
          type = listOf str;
          default = [];
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
