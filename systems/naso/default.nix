{ pkgs, lib, config, ... }:
{

  # Modules
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # My own configuration
  mine = {
    minimal = true;
    user.admin = false;
    user.groups = [ "cd" ];
    system.hostname = "naso";
    services = {
      ssh = true;
      docker = true;
    };
  };

  # Import the containers
  imports = [ ./containers ];

  # Set the permissions for the disk drive
  services.udev.extraRules = ''
    KERNEL="sr0", SYMLINK="cdrom", GROUP="cd"
  '';

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
        sender = builtins.replaceStrings [ "\n" "\t" ] [ "" "" ] (lib.strings.fileContents /data/local/mail/account);
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

  # File Systems

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
