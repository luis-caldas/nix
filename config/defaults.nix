{ lib, ... }:
{

  # My general configurations for the system
  options.my.config = {

    # The boot options be it MBR GRUB or EFI
    boot = {

      efi = mkOption {
        description = "Use EFI for boot";
        type = lib.types.bool;
        default = true;
      };

      grub = mkOption {
        description = "Use GRUB for boot, otherwise systemd-boot is used";
        type = lib.types.bool;
        default = false;
      };

      timeout = mkOption {
        description = "Timeout for the boot entry selection";
        type = lib.types.int;
        default = 60;
      };

      default = mkOption {
        description = "Default entry to be picked when using GRUB";
        type = lib.types.int;
        default = 0;
      };

      device = mkOption {
        description = "Device to install MBR GRUB onto";
        type = lib.types.str;
        default = "nodev";
      };

      prober = mkOption {
        description = "Probe the disks for OSs on GRUB";
        type = lib.type.bool;
        default = false;
      };

      tune = mkOption {
        description = "Play tune on GRUB";
        type = lib.type.bool;
        default = false;
      };

      top = mkOption {
        description = "Initilise `top` on TTY8";
        type = lib.type.bool;
        default = false;
      };

      override = mkOption {
        description = "Do not configure boot";
        type = lib.type.bool;
        default = false;
      };

    };

    # Kernel specific options
    kernel = {

      params = mkOptions {
        description = "Extra parameters for the kernel line on boot";
        type = lib.type.listOf lib.type.str;
        default = [];
      };

    };

    # User configuration
    user = rec {

      name = mkOptions {
        description = "Name of the main user";
        type = lib.type.str;
        default = "lu";
      };

      uid = mkOptions {
        description = "User ID of the main user";
        type = lib.type.int;
        default = 1000;
      };

      gid = mkOptions {
        description = "Group ID of the main users group";
        type = lib.type.int;
        default = 1000;
      };

      desc = mkOptions {
        description = "Description / GECOS / Full Name";
        type = lib.type.str;
        default = "Luis";
      };

      groups = mkOptions {
        description = "Extra groups for the user";
        type = lib.type.listOf lib.type.str;
        default = [];
      };

      admin = mkOptions {
        description = "Enable `sudo` command for user";
        type = lib.type.bool;
        default = true;
      };

      pass = mkOptions {
        description = "Default password for the user";
        type = lib.type.str;
        default = "functional";
      };

      autologin = mkOptions {
        description = "Enable TTY autologin for the user";
        type = lib.type.bool;
        default = false;
      };

      # Git configuration
      git = {

        name = mkOption {
          description = "Name shown for `git`";
          type = lib.type.str;
          default = "Luis";
        };

        email = mkOption {
          description = "Email shown for `git`";
          type = lib.type.str;
          default = "luis@caldas.ie";
        };

      };

    };

    # System configuration
    system = {

      hostname = mkOption {
        description = "Hostname for this system";
        type = lib.type.str;
        default = "forgotten";
      };

      timezone = mkOption {
        description = "Timezone for the system";
        type = lib.type.str;
        default = "Europe/Dublin";
      };

      locale = mkOption {
        description = "System locale";
        type = lib.type.str;
        default = "en_IE.UTF-8";
      };

      # The general location of the closest airport
      location = {

        latitude = mkOptions {
          description = "Positional latitude";
          type = lib.type.float;
          default = 53.3498;
        };

        longitude = mkOptions {
          description = "Positional longitude";
          type = lib.type.float;
          default = -6.2603;
        };

      };

      layout = mkOption {
        description = "Preferred keyboard layouts in order";
        type = lib.type.listOf lib.type.str;
        default = [ "ie" "us" ];
      };

      # Greeting messages for the TTY
      getty = {

        greeting = mkOption {
          description = "The greeting message on TTY login";
          type = lib.type.str;
          default = "\\S{PRETTY_NAME} @ \\r \\m \\b \\l\nSystem initiated successfully";
        };

        help = mkOption {
          description = "The help message on TTY login";
          type = lib.type.str;
          default = "You shouldn't need help at this point";
        };

      };

      motd = mkOptions {
        description = "The message of the day";
        type = lib.type.str;
        default = "Welcome back";
      };

    };

    # All the system services
    services = {

    };

    # Whether to make the system minimal
    # Less stuff to download and install
    minimal = mkOptions {
      description = "Make the system minimal";
      type = lib.type.bool;
      default = false;
    };

    # General networking options
    network = {

      # MAC configurations for NetworkManager
      mac = {

        cable = mkOption {
          description = "MAC address of the ethernet interface";
          type = lib.type.str;
          default = "stable";
        };

        wifi = mkOption {
          description = "MAC address of the wifi interface";
          type = lib.type.str;
          default = "stable";
        };

      };

      # Firewall options
      firewall = {

        enable = mkOption {
          description = "Enable firewall blocking";
          type = lib.type.bool;
          default = false;
        };

        ping = mkOption {
          description = "Allow device to reply to pings";
          type = lib.type.bool;
          default = true;
        };

      };

    };

    # All the services for the system
    services = {

      ssh = mkOption {
        description = "Enable the SSH service";
        type = lib.type.bool;
        default = false;
      };

      avahi = mkOption {
        description = "Enable avahi service";
        type = lib.type.bool;
        default = false;
      };

      docker = mkOption {
        description = "Enable the docker service";
        type = lib.type.bool;
        default = false;
      };

      printing = mkOption {
        description = "Enable the CUPS printing service";
        type = lib.type.bool;
        default = false;
      };

      # Virtualisation configuration
      virt = {

        enable = mkOption {
          description = "Enable the libvirt service";
          type = lib.type.bool;
          default = false;
        };

        swtpm = mkOption {
          description = "Enable TPM emulation for it";
          type = lib.type.bool;
          default = false;
        };

      };

      # Startup custom scripts
      startup = {

        permit = mkOption {
          description = "List of files to make permissible to the default user at startup";
          type = lib.type.listOf lib.type.str;
          default = [];
        };

        create = mkOption {
          description = "List of files to create at startup";
          type = lib.type.listOf lib.type.str;
          default = [];
        };

        start = mkOption {
          description = "List of scripts to run at startup";
          type = lib.type.listOf lib.type.str;
          default = [];
        };

      };

    };

    # Memory compression
    zram = mkOption {
      description = "Use ZRAM";
      type = lib.type.bool;
      default = false;
    };

    # Enable all the games
    games = mkOption {
      description = "Enable games";
      type = lib.type.bool;
      default = false;
    };

    # Enable LaTeX
    tex = mkOption {
      description = "Enable LaTeX";
      type = lib.type.bool;
      default = false;
    };

    # Enable audio
    audio = mkOption {
      description = "Enable audio";
      type = lib.type.bool;
      default = false;
    };

    # Enable bluetooth
    bluetooth = mkOption {
      description = "Enable bluetooth";
      type = lib.type.bool;
      default = false;
    };

  };

}
