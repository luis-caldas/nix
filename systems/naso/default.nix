{ pkgs, lib, config, ... }: let

  ##############
  # Containers #
  ##############

  # Shared information
  shared = {

    # Configure all the needed networks
    networks = pkgs.functions.container.createNames (let
      default = "default";
    in {
      simplifierIn = default;
      dataIn = {
        # Defaults
        "${default}" = [
          # Front
          "front"  # Should only be used for proxy
          # Manage
          "manage"
          # Games
          "games"
          # Share
          "share"
          # Vault
          "vault"
        ];
        # Cloud
        cloud = [ default "internal" ];
        # Mail
        mail = [ default "web" ];
        # Download
        download = [ "torrent" "usenet" "arr" ];
        # Git
        git = [ default "internal" ];
        # Media
        media = [ "jellyfin" "komga" "navidrome" "simple" ];
        # Recipe
        recipe = [ default "internal" ];
        # Social
        social = {
          default = [ default "internal" "admin" ];
          bridge = {
            whats = [ default "internal" ];
            sms = [ default "internal" ];
          };
        };
        # Track
        track = [ default "internal" ];
        # Workout
        workout = [ default "internal" "database" ];
      };
    });

    # Keep track of all the names
    names = pkgs.functions.container.createNames { dataIn = {
      # Non split containers
      app = [
        # Manage
        "portainer"
        # Share
        "samba" "shout"
        # Media
        "jellyfin" "komga" "shower"
        # Gaming
        "emulator"
        # Music
        "music"
        # Vault
        "vault"
      ];
      # Front
      front = [ "app" "access" ];
      # Download
      download = {
        app = [ "torrent" "usenet" ];
        arr = [
          "fetch" "series" "films" "music" "subtitles"
        ];
      };
      # Track
      track = [ "app" "database" ];
      # Workout
      wger = {
        app = [ "app" "cache" "database" "web" ];
        celery = [ "worker" "beat" "flower" ];
      };
      # Recipe
      tandoor = [ "app" "database" ];
      # Git
      gitea = [ "app" "database" ];
      # Social
      matrix = {
        app = [ "app" "database" "admin" ];
        bridge = rec {
          app = [ "whats" "discord" "telegram" "slack" "signal" "meta" "line" "sms" ];
          database = app;
        };
      };
      # Mail
      mail = [ "app" "web" ];
      # Cloud
      cloud = [ "app" "maria" "redis" "proxy" "cron" ];
    };};

  };

  # Build the whole project
  builtProjects = pkgs.functions.container.projects ./containers shared;

in {

  ########
  # Boot #
  ########

  # Modules
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  #######
  # Own #
  #######

  # My own configuration
  mine = {
    minimal = true;
    user.admin = false;
    user.groups = [ "cdrom" ];
    system.hostname = "naso";
    services = {
      ssh = true;
      docker = true;
      prometheus = {
        enable = true;
        password = "/data/local/prometheus/pass";
      };
    };
  };

  ##############
  # Containers #
  ##############

  # Containers
  virtualisation.arion.projects = builtProjects;

  # Create all the needed dependencies
  systemd.services = pkgs.functions.container.createDependencies builtProjects;

  # Publish Avahi
  # Which is needed to advertise the network share
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles.smb = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
      </service-group>
    '';
  };

  #######
  # UPS #
  #######

  # UPS client
  power.ups = {

    enable = true;
    mode = "netclient";
    schedulerRules = "${pkgs.functions.ups.clientSched}";

    # UPS Monitor
    upsmon = {

      # Connection
      monitor.main = {
        system = "apc@router";
        powerValue = 1;
        user = "admin";
        passwordFile = "/data/local/nut/pass";
        type = "secondary";
      };

      # Settings
      settings = pkgs.functions.ups.sharedConf // {
        # Binary Scheduler
        NOTIFYCMD = "${pkgs.nut}/bin/upssched";
        # Flags to be notified
        NOTIFYFLAG = pkgs.functions.ups.mapNotifyFlags [
          "ONLINE" "ONBATT"
        ] pkgs.functions.ups.defaultNotify;
      };

    };

  };

  #########
  # Email #
  #########

  # Allow msmtp to work with my configs
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/data/local/mail/alias";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = let
      mailDomain = lib.strings.fileContents /data/local/mail/domain;
      accountMail = lib.strings.fileContents /data/local/mail/account;
    in {
      default = {
        host = mailDomain;
        passwordeval = "${pkgs.coreutils}/bin/cat /data/local/mail/password";
        user = accountMail;
        from = accountMail;
      };
    };
  };

  ###############
  # Disk Health #
  ###############

  # Set up SMARTD
  services.smartd = {
    enable = true;
    autodetect = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    notifications = {
      test = true;
      wall.enable = false;
      mail = {
        enable = true;
        sender = builtins.replaceStrings [ "\n" "\t" ] [ "" "" ]
          (lib.strings.fileContents /data/local/mail/account);
        recipient = "root";
        mailer = "${pkgs.msmtp}/bin/msmtp";
      };
    };
  };

  # Set up ZFS ZED
  services.zfs.zed = {
    enableMail = false;
    settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";

      ZED_EMAIL_ADDR = [ "root" ];

      # Cat needed to get stdin
      ZED_EMAIL_PROG = "${pkgs.writeShellScript "zed-email" ''
        cat <(echo -e "Subject: ''${1}\r\n") - | "${pkgs.msmtp}/bin/msmtp" "''${2}"
      ''}";
      ZED_EMAIL_OPTS = "'@SUBJECT@' '@ADDRESS@'";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };

  # Add zfs scrubbing
  services.zfs.autoScrub = {
    enable = true;
    interval = "Fri, 03:00";
    pools = [ "bunker" "chunk" ];
  };

  ################
  # File Systems #
  ################

  fileSystems."/" =
    { device = "into/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F62C-297C";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "into/home";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "into/tmp";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "into/nix";
      fsType = "zfs";
    };

  fileSystems."/data/local" =
    { device = "into/data";
      fsType = "zfs";
    };

  fileSystems."/data/bunker/data" =
    { device = "bunker/data";
      fsType = "zfs";
    };

  fileSystems."/data/bunker/cloud" =
    { device = "bunker/cloud";
      fsType = "zfs";
    };

  fileSystems."/data/bunker/main" =
    { device = "bunker/main";
      fsType = "zfs";
      options = [ "nofail" "ro" ];
    };

  fileSystems."/data/bunker/everything" =
    { device = "bunker/everything";
      fsType = "zfs";
      options = [ "nofail" "ro" ];
    };

  fileSystems."/data/chunk" =
    { device = "chunk/bundle";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/118dc015-fd73-456c-86fd-00aa279b0fa9"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "23.05";

}
