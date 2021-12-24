{ lib, config, pkgs, ... }:
{

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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
      mailDomain = builtins.readFile /data/local/mail/domain;
      accountMail = builtins.readFile /data/local/mail/account;
    in
    {
      default = {
        host = mailDomain;
        passwordeval = "cat /data/local/mail/password";
        user = accountMail;
        from = accountMail;
      };
    };
  };

  services.zfs.zed = {
    enableMail = false;
    settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";

      ZED_EMAIL_ADDR = [ "root" ];
      ZED_EMAIL_PROG = let
        textFile = pkgs.writeTextFile {
          name = "mail"; executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            "${pkgs.coreutils}/bin/cat" <("${pkgs.coreutils}/bin/echo" -e "Subject: ''${1}\r\n") - | "${pkgs.msmtp}/bin/msmtp" "''${2}"
          '';
        }; in "${textFile}";
      ZED_EMAIL_OPTS = "'@SUBJECT@' '@ADDRESS@'";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };

  fileSystems."/" =
    { device = "into/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9B05-BBE0";
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

  fileSystems."/data/bunker" =
    { device = "bunker/main";
      fsType = "zfs";
    };

  fileSystems."/data/storr" =
    { device = "storr/main";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
