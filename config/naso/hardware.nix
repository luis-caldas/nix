{ my, mfunc, lib, config, pkgs, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Publish avahi
  services.avahi = {
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles = {
      smb = ''
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
  };

  # UPS client
  power.ups = {
    enable = true;
    mode = "netclient";
    schedulerRules = "/data/local/safe/nut/upssched.conf";
  };
  users = {
    users.nut = {
      isSystemUser = true;
      group = "nut";
      home = "/var/lib/nut";
      createHome = true;
    };
    groups.nut = { };
  };
  environment.etc = {
    "nut/upsmon.conf".source = "/data/local/safe/nut/upsmon.conf";
  };
  systemd.services.upsd = lib.mkForce {};
  systemd.services.upsdrv = lib.mkForce {};

  # Create networks for my containers
  system.activationScripts.mkVPN = let
    docker = config.virtualisation.oci-containers.backend;
    dockerBin = "${pkgs.${docker}}/bin/${docker}";
  in ''
    ${dockerBin} network inspect ${networkName} >/dev/null 2>&1 || ${dockerBin} network create vpn --subnet 172.20.0.0/16
  '';

  # Services for creating my needed containerised networks
  systemd.services = let

    # Names of the databases that will be created
    names = [ "database" "media" ];

    # Networks calculation
    networks = let
      startRange = "172.16";
      offset = 70;
      subnet = "/24";
    # Create the attrset of networks and names
    in builtins.listToAttrs (lib.imap0 (index: eachName: {
      name = eachName;
      value = "${startRange}.${builtins.toString (offset + index)}.0${subnet}";
    }) names);

    # Docker binary
    docker = builtins.trace networks config.virtualisation.oci-containers.backend;
    dockerBin = "${pkgs.${docker}}/bin/${docker}";

    # Name prefix for service
    prefix = "container-network-start";

  in
    # Whole activation script
    builtins.listToAttrs (
      lib.mapAttrsToList (eachName: eachValue: {
        name = "${prefix}-${eachName}";
        value = {
          description = "Create the needed networks for containers";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            # Put a true at the end to prevent getting non-zero return code,
            # which will crash the whole service.
            check=$(${dockerBin} network ls | grep "${eachName}" || true)
            if [ -z "$check" ]; then
              "${dockerBin}" network create "${eachName}" --driver bridge --subnet ${eachValue}
            else
              echo "${eachName} already exists in docker"
            fi
          '';
        };
      })
    ) networks;

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    # Media serving samba instance
    media = {
      image = "dperson/samba";
      environment = {
        TZ = my.config.system.timezone;
        USERID = builtins.toString my.config.user.uid;
        GROUPID = builtins.toString my.config.user.gid;
      };
      cmd = [
        "-g" "log level = 2" # Global config
        "-n" # NMBF
        "-r" # Remove recycle bin
        "-S" # Disable minimum SMB2
        "-s" "media;/media;yes;no;yes;all;;;Share for media files" # Share config
        # "-s" "google;/google;yes;yes;yes;all;;;Google saved files"
        "-s" "ps2;/ps2;yes;no;yes;all;;;PS2 Games"
        "-w" "WORKGROUP" # Default workgroup
        "-W" # Wide link support
      ];
      volumes = [
        # "/data/bunker/everything/vault/untouched/google-parents:/google"
        "/data/storr/media:/media"
        "/data/local/config/ps2:/ps2"
        "/data/storr/media/games/roms/ps2/dvd:/ps2/DVD:ro"
        "/data/storr/media/games/roms/ps2/cd:/ps2/CD:ro"
        "/data/storr/media/games/roms/ps2/art:/ps2/ART:ro"
      ];
      ports = [
        "137:137/udp"
        "138:138/udp"
        "139:139/tcp"
        "445:445/tcp"
      ];
      extraDockerOptions = [ "--network=media" ];
    };

    # Database
    maria = {
      image = "mariadb:latest";
      environment = {
        TZ = my.config.system.timezone;
      };
      environmentFiles = [ /data/local/safe/env/mariadb.env ];
      volumes = [
        "/data/bunker/safe/mariadb:/data"
      ];
      extraOptions = [ "--network=database" ];
    };

    # Vaultwarden
    warden = {
      image = "vaultwarden/server:latest";
      environment = {
        TZ = my.config.system.timezone;
        ROCKET_TLS="{certs=\"/ssl/main.pem\",key=\"/ssl/main.key\"}";
        SIGNUPS_ALLOWED="false";
      };
      environmentFiles = [ /data/local/safe/env/warden.env ];
      volumes = [
        "/data/local/ssl:/ssl"
        "/data/bunker/safe/docker/config/warden:/data"
      ];
      ports = [
        "8443:80/tcp"
      ];
      extraOptions = [ "--network=database" ];
    };

    # Nextcloud
    cloud = {
      image = "nextcloud";
      environment = {
        TZ = my.config.system.timezone;
      };
      environmentFiles = [  ];
      volumes = [
        "/data/local/config/nextcloud:/var/www/html"
        "/data/bunker/cloud:/var/www/html/data"
      ];
      ports = [
        "443:80/tcp"
      ];
      extraOptions = [ "--network=database" ];
    };

    # Deluge instance for downloading
    delusion = {
      image = "lscr.io/linuxserver/deluge";
      environment = {
        TZ = my.config.system.timezone;
        PUID = builtins.toString my.config.user.uid;
        PGID = builtins.toString my.config.user.gid;
      };
      volumes = [
        "/data/storr/media/downloads:/downloads"
        "/data/local/config/deluge:/config"
      ];
      ports = [
        "8112:8112/tcp"
      ];
      extraOptions = [ "--network=media" ];
    };

    # Service for mangas
    komga = {
      image = "gotson/komga";
      environment = {
        TZ = my.config.system.timezone;
      };
      user = "${builtins.toString my.config.user.uid}:${builtins.toString my.config.user.gid}";
      volumes = [
        "/data/local/config/komga:/config"
        "/data/storr/media/manga:/data:ro"
      ];
      ports = [
        "8080:8080/tcp"
      ];
      extraOptions = [ "--network=media" ];
    };

    # AriaNG Web App & Aria2
    aria = {
      image = "hurlenko/aria2-ariang";
      environment = {
        PUID = builtins.toString my.config.user.uid;
        PGID = builtins.toString my.config.user.gid;
        ARIA2RPCPORT = "6880";
      };
      ports = [
        "6880:8080/tcp"
      ];
      volumes = [
        "/data/storr/media/downloads:/aria2/data"
        "/data/local/config/aria:/aria2/conf"
      ];
      extraOptions = [ "--init" "--network=media" ];
    };

    # Web Service Discovery for Microsoft
    shout = {
      image = "jonasped/wsdd";
      environment = {
        TZ = my.config.system.timezone;
        HOSTNAME = my.path;
        WORKGROUP = "WORKGROUP";
      };
      extraOptions = [ "--network=host" ];
    };

  };

  # Allow msmtp to work with my configs
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/data/local/safe/mail/alias";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = let
      mailDomain = mfunc.safeReadFile /data/local/safe/mail/domain;
      accountMail = mfunc.safeReadFile /data/local/safe/mail/account;
    in
    {
      default = {
        host = mailDomain;
        passwordeval = "${pkgs.coreutils}/bin/cat /data/local/safe/mail/password";
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
        sender = builtins.replaceStrings [ "\n" "\t" ] [ "" "" ] (mfunc.safeReadFile /data/local/safe/mail/account);
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

  fileSystems."/data/bunker/safe" =
    { device = "bunker/safe";
      fsType = "zfs";
    };

  fileSystems."/data/bunker/cloud" =
    { device = "bunker/cloud";
      fsType = "zfs";
    };

  fileSystems."/data/bunker/main" =
    { device = "bunker/main";
      fsType = "zfs";
      options = [ "nofail" ];
    };

  fileSystems."/data/bunker/everything" =
    { device = "bunker/everything";
      fsType = "zfs";
      options = [ "nofail" "ro" ];
    };

  fileSystems."/data/storr" =
    { device = "storr/main";
      fsType = "zfs";
      options = [ "nofail" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/118dc015-fd73-456c-86fd-00aa279b0fa9"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
