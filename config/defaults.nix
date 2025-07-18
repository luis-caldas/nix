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

      prometheus = {

        enable = mkEnableOption "Prometheus";

        collectors = mkOption {
          description = "Extra collectors for the Prometheus node exporter";
          type = listOf str;
          default = [];
        };

        password = mkOption {
          description = "Location of the Prometheus password file in bcrypt format";
          type = str;
          default = "";
        };

        ssl = {

          cert = mkOption {
            description = "Location of the Prometheus SSL Cert file";
            type = str;
            default = "";
          };
          key = mkOption {
            description = "Location of the Prometheus SSL Key file";
            type = str;
            default = "";
          };

        };

      };

      # Virtualisation configuration
      virtual = {

        enable = mkEnableOption "libvirt";

        swtpm = mkEnableOption "TPM Emulation";

        vmware = mkEnableOption "VMWare Server";

        android = mkEnableOption "Android Virtualisation";

      };

    };

    # All the graphical configurations
    graphics = {

      enable = mkEnableOption "Graphical Inteface";

      cloud = mkOption {
        description = "Enable NextCloud Client at Startup";
        type = bool;
        default = false;
      };

      numlock = mkOption {
        description = "Startup system with NumLock enabled";
        type = bool;
        default = true;
      };

      cursor = {

        name = mkOption {
          description = "Name of the default cursor used";
          type = str;
          default = "Breeze_Hacked";
        };

        size = mkOption {
          description = "Default size of the cursor";
          type = int;
          default = 24;
        };

      };

      icon = mkOption {
        description = "Name of the preferred icon theme to use";
        type = str;
        default = "Papirus-Light";
      };

      iconDark = mkOption {
        description = "Name of the preferred icon theme to use when dark";
        type = str;
        default = "Papirus-Dark";
      };

      theme = mkOption {
        description = "Name of the preferred system theme to use";
        type = str;
        default = "Adwaita";
      };

      themeDark = mkOption {
        description = "Name of the preferred system theme to use when dark";
        type = str;
        default = "Adwaita-dark";
      };

      dark = mkOption {
        description = "Enable dark mode by default";
        type = bool;
        default = true;
      };

      workspaces = mkOption {
        description = "List of workspaces";
        type = listOf str;
        default = [
          "Main" "Browse" "Mail" "Docs" "Game" "Design" "Web" "Links" "Music"
        ];
      };

      applications = {

        terminal = mkOption {
          type = str;
          default = "Alacritty.desktop";
        };

        email = mkOption {
          type = str;
          default = "org.gnome.Evolution.desktop";
        };

        chat = mkOption {
          type = str;
          default = "element-desktop.desktop";
        };

        text = mkOption {
          type = str;
          default = "org.gnome.TextEditor.desktop";
        };

        audio = mkOption {
          type = str;
          default = "org.gnome.Decibels.desktop";
        };

        video = mkOption {
          type = str;
          default = "io.github.celluloid_player.Celluloid.desktop";
        };

        image = mkOption {
          type = str;
          default = "org.gnome.Loupe.desktop";
        };

        files = mkOption {
          type = str;
          default = "org.gnome.Nautilus.desktop";
        };

        archive = mkOption {
          type = str;
          default = "org.gnome.FileRoller.desktop";
        };

        pdf = mkOption {
          type = str;
          default = "org.gnome.Evince.desktop";
        };

        calendar = mkOption {
          type = str;
          default = "org.gnome.Calendar.desktop";
        };

        iso = mkOption {
          type = str;
          default = "gnome-disk-image-mounter.desktop";
        };

      };

      favourites = mkOption {
        description = "List of desktop items to be favourites, items can be a generic application name";
        type = listOf str;
        default = [
          "terminal"
          "browser"
          "email"
          "codium.desktop"
          "deck.desktop"
          "chat"
          "feishin.desktop"
          "files"
          "net.nokyan.Resources.desktop"
        ];
      };

      keybindings = mkOption {
        description = "Extra keybindings to launch applications, items can be a generic application name";
        type = attrsOf str;
        default = {
          terminal = "Return";
          files = "E";
        };
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
      common = mkOption {
        description = "Extensions for all the installations";
        type = listOf str;
        default = [
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
          "nngceckbapebfimnlniiiahkandclblb" # bitwarden client
          "fnaicdffflnofjppbagibeoednhnbjhg" # floccus bookmarks manager
          "gbmdgpbipfallnflgajpaliibnhdgobh" # json viewer
          # "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
          # "padekgcemlokbadohgkifijomclgjgif" # switchy proxy omega
          # "cnojnbdhbhnkbcieeekonklommdnndci" # search by image
          # "hkgfoiooedgoejojocmhlaklaeopbecg" # picture in picture
          # "dneaehbmnbhcippjikoajpoabadpodje" # old reddit
        ];
      };

      enableFlags = mkOption {
        description = "Flags to be enabled";
        type = listOf str;
        default = [
          "enable-extension-autoupdate"
        ];
      };

      disableFlags = mkOption {
        description = "Flags to be disabled";
        type = listOf str;
        default = [
          "global-shortcuts-portal"
        ];
      };

      name = mkOption {
        description = "Browser name / command";
        type = str;
        default = "cromite";
      };

      others = mkOption {
        description = "Extensions for specific installations";
        type = listOf attrs;
        default = [

          # The main installation
          { name = "main";
            extensions = [ "bjilljlpencdcpihofiobpnfgcakfdbe" ];  # clear browsing data
            key = "N";
          }

          # The persistent installation
          { name = "persistent";
            extensions = [];
            key = "M";
          }

          # The unchanged installation
          { name = "normal";
            extensions = [];
            key = "B";
          }

        ];
      };

      apps = mkOption {
        description = "Extra applications that use the browser";
        type = listOf (attrsOf str);
        default = [
          { name = "deck"; icon = "plan"; url = "https://redirect.caldas.ie"; }
          { name = "notes"; icon = "notes"; url = "https://redirect.caldas.ie"; }
          { name = "files"; icon = "nextcloud"; url = "https://redirect.caldas.ie"; }
          { name = "jellyfin-web"; icon = "jellyfin"; url = "https://redirect.caldas.ie"; }
          { name = "whatsapp-web"; icon = "whatsapp"; url = "https://web.whatsapp.com"; }
          { name = "discord-web"; icon = "discord"; url = "https://discord.com/app"; }
          { name = "github-web"; icon = "github"; url = "https://github.com"; }
          { name = "chess-web"; icon = "chess"; url = "https://chess.com"; }
          { name = "spotify-web"; icon = "spotify"; url = "https://open.spotify.com"; }
          { name = "youtube-web"; icon = "youtube"; url = "https://www.youtube.com"; }
          { name = "youtube-music-web"; icon = "youtube-music"; url = "https://music.youtube.com"; }
          { name = "suno"; icon = "atunes"; url = "https://suno.com/"; }
          { name = "defence-forces"; icon = "europa-universalis-IV"; url = "https://irishdefenceforces.workvivo.com"; }
          { name = "canvas"; icon = "applications-education"; url = "https://cit.instructure.com"; }
        ];
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
