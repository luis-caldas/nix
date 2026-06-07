{ lib, ... }:
{

  # My general configurations for the system
  options.mine = with lib; with types; {

    # The boot options be it MBR GRUB or EFI
    boot = {

      secure = mkOption {
        description = "Use Secure Boot.";
        type = bool;
        default = false;
      };

      efi = mkOption {
        description = "Use EFI for boot.";
        type = bool;
        default = true;
      };

      grub = mkOption {
        description = "Use GRUB for boot, otherwise systemd boot is used.";
        type = bool;
        default = false;
      };

      timeout = mkOption {
        description = "Timeout for boot entry selection.";
        type = int;
        default = 1;
      };

      default = mkOption {
        description = "Default entry to pick when using GRUB.";
        type = int;
        default = 0;
      };

      devices = mkOption {
        description = "Device to install MBR GRUB onto.";
        type = listOf str;
        default = [ "nodev" ];
      };

      prober = mkOption {
        description = "Probe disks for operating systems in GRUB.";
        type = bool;
        default = false;
      };

      tune = mkOption {
        description = "Play a tune in GRUB.";
        type = bool;
        default = false;
      };

      top = mkOption {
        description = "Initialise `top` on TTY8.";
        type = bool;
        default = false;
      };

      override = mkOption {
        description = "Do not configure boot.";
        type = bool;
        default = false;
      };

    };

    # Kernel specific options
    kernel = {

      text = mkOption {
        description = "Extra text mode for the systems.";
        type = bool;
        default = true;
      };

      params = mkOption {
        description = "Extra parameters for the kernel command line at boot.";
        type = listOf str;
        default = [];
      };

    };

    # User configuration
    user = {

      name = mkOption {
        description = "Name of the main user.";
        type = str;
        default = "lu";
      };

      uid = mkOption {
        description = "User ID of the main user.";
        type = int;
        default = 1000;
      };

      gid = mkOption {
        description = "Group ID of the main user's group.";
        type = int;
        default = 1000;
      };

      desc = mkOption {
        description = "Description, GECOS, or full name.";
        type = str;
        default = "Luis";
      };

      groups = mkOption {
        description = "Extra groups for the user.";
        type = listOf str;
        default = [];
      };

      admin = mkOption {
        description = "Enable the `sudo` command for the user.";
        type = bool;
        default = false;
      };

      pass = mkOption {
        description = "Default password for the user.";
        type = str;
        default = "functional";
      };

      autologin = mkOption {
        description = "Enable TTY autologin for the user.";
        type = bool;
        default = false;
      };

      # Git configuration
      git = {

        name = mkOption {
          description = "Name shown for `git`.";
          type = str;
          default = "Luis";
        };

        email = mkOption {
          description = "Email shown for `git`.";
          type = str;
          default = "luis@caldas.ie";
        };

      };

    };

    # System configuration
    system = {

      hostname = mkOption {
        description = "Hostname for this system.";
        type = str;
        default = "forgotten";
      };

      timezone = mkOption {
        description = "Timezone for the system.";
        type = str;
        default = "Europe/Dublin";
      };

      locale = mkOption {
        description = "System locale.";
        type = str;
        default = "en_IE.UTF-8";
      };

      layout = lib.mkOption {
        description = "Preferred keyboard layouts in order.";
        type = listOf str;
        default = [ "ie" "us" ];
      };

      # The general location of the closest airport
      location = {

        latitude = mkOption {
          description = "Position latitude.";
          type = float;
          default = 53.3498;
        };

        longitude = mkOption {
          description = "Position longitude.";
          type = float;
          default = -6.2603;
        };

      };

      # Greeting messages for the TTY
      getty = {

        greeting = mkOption {
          description = "Greeting message for TTY login.";
          type = str;
          default = "\\S{PRETTY_NAME} @ \\r \\m \\b \\l\nSystem initiated successfully";
        };

        help = mkOption {
          description = "Help message for TTY login.";
          type = str;
          default = "You shouldn't need help at this point";
        };

      };

      motd = mkOption {
        description = "Message of the day.";
        type = str;
        default = "Welcome back";
      };

    };

    # General networking options
    network = {

      # MAC configurations for NetworkManager
      mac = mkOption {
        description = "How to set MAC addresses.";
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

      snapshot = mkEnableOption "ZFS Snapshot";

      avahi = mkEnableOption "Avahi";

      docker = {

        enable = mkEnableOption "docker";

        manager = mkEnableOption "Docker Manager";

      };

      printing = mkEnableOption "CUPS";

      fwupd = mkEnableOption "Firmware Update";

      # Virtualisation configuration
      virtual = {

        enable = mkEnableOption "libvirt";

        manager = mkEnableOption "Management of libvirt";

        remote = mkEnableOption "Enable remote access management";

        swtpm = mkEnableOption "TPM Emulation";

        vmware = mkEnableOption "VMWare Server";

        android = mkEnableOption "Android Virtualisation";

      };

    };

    # All the graphical configurations
    graphics = {

      enable = mkEnableOption "Graphical Inteface";

      simple = mkEnableOption "Simpler Interface";

      cloud = mkOption {
        description = "Enable Nextcloud Client at startup.";
        type = bool;
        default = false;
      };

      sunshine = mkOption {
        description = "Remote access.";
        type = bool;
        default = true;
      };

      numlock = mkOption {
        description = "Start the system with NumLock enabled.";
        type = bool;
        default = true;
      };

      cursor = {

        name = mkOption {
          description = "Name of the default cursor.";
          type = str;
          default = "Breeze_Hacked";
        };

        size = mkOption {
          description = "Default cursor size.";
          type = int;
          default = 24;
        };

      };

      icon = mkOption {
        description = "Name of the preferred icon theme.";
        type = str;
        default = "Papirus";
      };

      theme = mkOption {
        description = "Name of the preferred system theme.";
        type = str;
        default = "Adwaita";
      };

      workspaces = mkOption {
        description = "List of workspaces.";
        type = listOf str;
        default = [
          "Main" "Browse" "Mail" "Docs" "Game" "Design" "Web" "Links" "Music"
        ];
      };

      applications = {

        terminal = mkOption {
          description = "Default terminal application desktop entry.";
          type = str;
          default = "org.gnome.Console.desktop";
        };

        email = mkOption {
          description = "Default email application desktop entry.";
          type = str;
          default = "org.gnome.Evolution.desktop";
        };

        chat = mkOption {
          description = "Default chat application desktop entry.";
          type = str;
          default = "org.gnome.Fractal.desktop";
        };

        text = mkOption {
          description = "Default text editor application desktop entry.";
          type = str;
          default = "org.gnome.TextEditor.desktop";
        };

        notes = mkOption {
          description = "Default notes application desktop entry.";
          type = str;
          default = "org.gnome.gitlab.somas.Apostrophe.desktop";
        };

        audio = mkOption {
          description = "Default audio application desktop entry.";
          type = str;
          default = "org.gnome.Decibels.desktop";
        };

        video = mkOption {
          description = "Default video application desktop entry.";
          type = str;
          default = "org.gnome.Showtime.desktop";
        };

        image = mkOption {
          description = "Default image viewer application desktop entry.";
          type = str;
          default = "org.gnome.Loupe.desktop";
        };

        screenshot = mkOption {
          description = "Default screenshot application desktop entry.";
          type = str;
          default = "be.alexandervanhee.gradia.desktop";
        };

        files = mkOption {
          description = "Default file manager application desktop entry.";
          type = str;
          default = "org.gnome.Nautilus.desktop";
        };

        archive = mkOption {
          description = "Default archive manager application desktop entry.";
          type = str;
          default = "org.gnome.FileRoller.desktop";
        };

        pdf = mkOption {
          description = "Default PDF application desktop entry.";
          type = str;
          default = "org.gnome.Papers.desktop";
        };

        calendar = mkOption {
          description = "Default calendar application desktop entry.";
          type = str;
          default = "org.gnome.Calendar.desktop";
        };

        iso = mkOption {
          description = "Default ISO image application desktop entry.";
          type = str;
          default = "gnome-disk-image-mounter.desktop";
        };

        ide = mkOption {
          description = "Default IDE application desktop entry.";
          type = str;
          default = "codium.desktop";
        };

        music = mkOption {
          description = "Default music application desktop entry.";
          type = str;
          default = "spotify.desktop";
        };

        resources = mkOption {
          description = "Default resources monitor application desktop entry.";
          type = str;
          default = "net.nokyan.Resources.desktop";
        };

      };

      favourites = mkOption {
        description = "List of favourite desktop items, which can be generic application names.";
        type = listOf str;
        default = [
          "terminal"
          "browser"
          "email"
          "ide"
          "notes"
          "chat"
          "music"
          "files"
          "resources"
        ];
      };

      keybindings = mkOption {
        description = "Extra keybindings to launch applications, which can be generic application names.";
        type = attrsOf (oneOf [ str (attrsOf str) ]);
        default = {
          terminal = { key = "Return"; command = "kgx"; };
          files = { key = "E"; command = "nautilus --new-window"; };
          screenshot = { key = "G"; command = "gradia --screenshot"; };
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
        description = "Extra policies to add to the default Chromium installations.";
        type = attrs;
        default = {};
      };

      # Extension hashes for different Chromium types
      common = mkOption {
        description = "Extensions for all installations.";
        type = listOf str;
        default = [
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
          "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin v3
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden client
          "fnaicdffflnofjppbagibeoednhnbjhg" # Floccus bookmark manager
          "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
          # "gbmdgpbipfallnflgajpaliibnhdgobh" # json viewer
          # "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
          # "padekgcemlokbadohgkifijomclgjgif" # switchy proxy omega
          # "cnojnbdhbhnkbcieeekonklommdnndci" # search by image
          # "hkgfoiooedgoejojocmhlaklaeopbecg" # picture in picture
          # "dneaehbmnbhcippjikoajpoabadpodje" # old reddit
        ];
      };

      enableFlags = mkOption {
        description = "Flags to enable.";
        type = listOf str;
        default = [
          "enable-extension-autoupdate"
        ];
      };

      disableFlags = mkOption {
        description = "Flags to disable.";
        type = listOf str;
        default = [
          "global-shortcuts-portal"
          "restrict-gamepad-access"
          "system-keyboard-protection"
        ];
      };

      name = mkOption {
        description = "Browser name or command.";
        type = str;
        default = "chromium";
      };

      icon = mkOption {
        description = "Browser icon.";
        type = str;
        default = "browser360-beta";
      };

      others = mkOption {
        description = "Extensions for specific installations.";
        type = listOf attrs;
        default = [

          # The main installation
          { name = "main";
            extensions = [ "bjilljlpencdcpihofiobpnfgcakfdbe" ];  # Clear Browsing Data
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
        description = "Extra applications that use the browser.";
        type = listOf (attrsOf str);
        default = [
          { name = "deck"; icon = "plan"; url = "https://luis-caldas.github.io/redirector"; }
          { name = "chess-web"; icon = "chess"; url = "https://chess.com"; }
          { name = "youtube-web"; icon = "youtube"; url = "https://www.youtube.com"; }
          { name = "youtube-music-web"; icon = "youtube-music"; url = "https://music.youtube.com"; }
          { name = "suno"; icon = "atunes"; url = "https://suno.com/"; }
          { name = "defence-forces"; icon = "europa-universalis-IV"; url = "https://irishdefenceforces.workvivo.com"; }
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

    # Enable Bluetooth
    bluetooth = mkEnableOption "Bluetooth";

  };

}
