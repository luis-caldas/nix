{ my, mfunc, lib, config, pkgs, ... }:
let

  # Create all the services needed for the containers networks
  conatinerNetworksService = let
    # Names of networks and their subnets
    networks = {
      # Default networks for databases and the likes
      cloud = { range = "172.16.72.0/24"; };
      media = { range = "172.16.73.0/24"; };
      vault = { range = "172.16.74.0/24"; };
      message = { range = "172.16.75.0/24"; };
      # Proxy network
      proxy = { range = "172.30.0.0/16"; };
    };
  in
    my.containers.functions.addNetworks networks;

  # Default ssl port
  httpsPort = builtins.toString 8443;

in {

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Publish avahi
  services.avahi = {
    enable = true;
    nssmdns = true;
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
    schedulerRules = "/data/local/nut/upssched.conf";
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
    "nut/upsmon.conf".source = "/data/local/nut/upsmon.conf";
  };

  # Services needed
  systemd.services = {
    # To make ups shutdown work
    upsd = lib.mkForce {};
    upsdrv = lib.mkForce {};
  } //
  # Add the container network services too
  conatinerNetworksService;

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
      environmentFiles = [ /data/local/containers/media/samba.env ];
      cmd = [
        "-g" "log level = 2" # Global config
        "-n" # NMBF
        "-r" # Remove recycle bin
        "-S" # Disable minimum SMB2
        "-s" "media;/media;yes;no;no;all;;;Share for media files" # Share config
        "-s" "ps2;/ps2;yes;no;yes;all;;;PS2 Games"
        "-w" "WORKGROUP" # Default workgroup
        "-W" # Wide link support
      ];
      volumes = [
        "/data/storr/media:/media"
        "/data/local/containers/media/ps2:/ps2"
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
      extraOptions = [ "--network=media" ];
    };

    # Media proper
    jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      environment = {
        PUID = builtins.toString my.config.user.uid;
        PGID = builtins.toString my.config.user.gid;
        TZ = my.config.system.timezone;
      };
      volumes = [
        "/data/local/containers/jellyfin:/config"
      ] ++ (
        map (eachFolder: "/data/storr/media/${eachFolder}:/data/${eachFolder}:ro")
        [ "anime" "cartoons" "films" "series" ]
      );
      ports = [
        "8280:8096/tcp"
        "7359:7359/udp"
        "1900:1900/udp"
      ];
    };

    # Vaultwarden
    warden = {
      image = "vaultwarden/server:latest";
      environment = {
        TZ = my.config.system.timezone;
        SIGNUPS_ALLOWED = "false";
      };
      environmentFiles = [ /data/local/containers/warden/warden.env ];
      volumes = [
        "/data/bunker/data/containers/warden:/data"
      ];
      ports = [
        "8080:80/tcp"
      ];
      extraOptions = [ "--network=vault" ];
    };

    # ### Nextcloud
    # Database
    cloud-maria = {
      image = "mariadb:latest";
      environment = let
        cloudName = "cloud";
      in {
        TZ = my.config.system.timezone;
        MARIADB_DATABASE = cloudName;
        MARIADB_USER = cloudName;
      };
      environmentFiles = [ /data/local/containers/cloud/mariadb.env ];
      volumes = [
        "/data/bunker/data/containers/cloud/mariadb:/var/lib/mysql"
      ];
      extraOptions = [ "--network=cloud" "--ip=172.16.72.100" ];
    };
    # Redis
    cloud-redis = {
      image = "redis:latest";
      environment = {
        TZ = my.config.system.timezone;
      };
      volumes = [
        "/data/bunker/data/containers/cloud/redis:/data"
      ];
      cmd = [ "--save 60 1" ];
      extraOptions = [ "--network=cloud" "--ip=172.16.72.110" ];
    };
    # Application
    cloud = {
      image = "nextcloud";
      dependsOn = [ "cloud-maria" "cloud-redis" ];
      environment = {
        TZ = my.config.system.timezone;
        # Mariadb
        MYSQL_HOST = "172.16.72.100";
        MYSQL_DATABASE = "cloud";
        MYSQL_USER = "cloud";
        # Redis
        REDIS_HOST = "172.16.72.110";
        # Data
        NEXTCLOUD_DATA_DIR = "/data";
      };
      environmentFiles = [ /data/local/containers/cloud/cloud.env ];
      volumes = [
        "/data/bunker/data/containers/cloud/application:/var/www/html"
        "/data/bunker/cloud/cloud:/data"
      ];
      ports = [
        "8180:80/tcp"
      ];
      extraOptions = [ "--network=cloud" "--ip=172.16.72.10" ];
    };
    # Proxy HTTPS
    cloud-proxy = my.containers.functions.createProxy {
      name = "cloud";
      net = {
        name = "cloud";
        ip = "172.16.72.10";
        port = "80";
      };
      port = "9443";
      ssl = {
        key = "/data/local/containers/cloud/ssl/main.key";
        cert = "/data/local/containers/cloud/ssl/main.pem";
      };
      extraConfig = ''
          client_max_body_size 512M;
          client_body_timeout 300s;
          fastcgi_buffers 64 4K;
          location /.well-known/carddav {
              return 301 $scheme://$host:$server_port/remote.php/dav;
          }
          location /.well-known/caldav {
              return 301 $scheme://$host:$server_port/remote.php/dav;
          }
      '';
      extraOptions = [ "--ip=172.16.72.20" ];
    };

    # Matrix server
#    matrix = {
#      image = "matrixdotorg/synapse:latest";
#      environment = {
#        TZ = my.config.system.timezone;
#        UID = builtins.toString my.config.user.uid;
#        GID = builtins.toString my.config.user.gid;
#      };
#      volumes = [
#        "/data/bunker/data/containers/matrix:/data"
#      ];
#      extraOptions = [ "--network=message" "--ip=172.16.75.100" ];
#    };

    # Service for manga
    komga = {
      image = "gotson/komga";
      environment = {
        TZ = my.config.system.timezone;
      };
      user = "${builtins.toString my.config.user.uid}:${builtins.toString my.config.user.gid}";
      volumes = [
        "/data/local/containers/komga:/config"
        "/data/storr/media/manga:/data:ro"
      ];
      ports = [
        "8380:8080/tcp"
      ];
    };

    # QBittorrent instance for torrenting
    torrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = {
        TZ = my.config.system.timezone;
        PUID = builtins.toString my.config.user.uid;
        PGID = builtins.toString my.config.user.gid;
        WEBUI_PORT = "8112";
      };
      volumes = [
        "/data/local/containers/torrent:/config"
        "/data/storr/media/downloads:/downloads"
      ];
      ports = [
        "9080:8112/tcp"
      ];
    };

    # AriaNG Web App & Aria2
    aria = {
      image = "hurlenko/aria2-ariang";
      environment = {
        PUID = builtins.toString my.config.user.uid;
        PGID = builtins.toString my.config.user.gid;
        ARIA2RPCPORT = httpsPort;
      };
      ports = [
        "9180:8080/tcp"
      ];
      volumes = [
        "/data/local/containers/aria:/aria2/conf"
        "/data/storr/media/downloads:/aria2/data"
      ];
      extraOptions = [ "--init" ];
    };

    # Web Service Discovery for Microsoft
    shout = {
      image = "aovestdipaperino/wsdd2";
      environment = {
        TZ = my.config.system.timezone;
        HOSTNAME = my.path;
      };
      extraOptions = [ "--network=host" ];  # Needed for multicast
    };

    # Reverse proxy for all those services
    proxy = {
      image = "jc21/nginx-proxy-manager:latest";
      ports = [
        "80:80/tcp"
        "${httpsPort}:443/tcp"  # Temporary high range port
        "7080:81/tcp"
      ];
      volumes = [
        "/data/local/containers/proxy:/data"
      ];
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
      mailDomain = mfunc.safeReadFile /data/local/mail/domain;
      accountMail = mfunc.safeReadFile /data/local/mail/account;
    in
    {
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
        sender = builtins.replaceStrings [ "\n" "\t" ] [ "" "" ] (mfunc.safeReadFile /data/local/mail/account);
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

  system.stateVersion = "23.05";

}