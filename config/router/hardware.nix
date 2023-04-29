{ my, lib, config, mfunc, pkgs, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ "pcie_aspm=off" "amd_iommu=on" "iommu=pt" "pci=noaer" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # VFIO overrides for vms
  boot.initrd.preDeviceCommands = ''
    devices="0000:05:00.0 0000:05:00.1"
    for each_device in $devices; do
      echo "vfio-pci" > /sys/bus/pci/devices/$each_device/driver_override
    done
    modprobe -i vfio-pci
  '';

  # Enable ip forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Networling
  networking = {
    useDHCP = false;
    dhcpcd.extraConfig = ''
      noipv4ll
    '';
    networkmanager.enable = lib.mkForce false;
    interfaces = {
      enp4s0.useDHCP = true;
      pf-bridge = {
        useDHCP = true;
        macAddress = "ff:54:ff:00:00:01";
      };
    };
    bridges.pf-bridge.interfaces = [];
  };

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  # Autostart serial getty connection
  systemd.services."serial-getty@ttyRECOVER" = {
    enable = true;
    wantedBy = [ "getty.target" ];
    serviceConfig.Restart = "always";
  };

  # UPS configuration
  power.ups = {
    enable = true;
    mode = "netserver";
    ups.apc = {
      port = "auto";
      driver = "usbhid-ups";
      description = "APC Smart 2200VA UPS";
      directives = lib.mapAttrsToList (name: value: "${name} = \"${value}\"") {
        vendorid = "051D";
        productid = "0002";
      };
    };
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
    "nut/upsd.conf".source = "/data/local/nut/upsd.conf";
    "nut/upsd.users".source = "/data/local/nut/upsd.users";
    "nut/upsmon.conf".source = "/data/local/nut/upsmon.conf";
  };

  # Configure email sender
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

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    # DNS Server
    dns = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = my.config.system.timezone;
        DNS1 = "1.1.1.1";
        DNS2 = "1.0.0.1";
      };
      environmentFiles = [ /data/local/safe/adblock.env ];
      volumes = [
        "/data/local/docker/config/pihole/etc:/etc/pihole"
        "/data/local/docker/config/pihole/dnsmasq:/etc/dnsmasq.d"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "81:80/tcp"
      ];
      extraOptions = [ "--dns=127.0.0.1" ];
    };

    # NUT server monitor
    nut = {
      image = "teknologist/webnut:latest";
      environment = {
        TZ = my.config.system.timezone;
      };
      environmentFiles = [ /data/local/safe/ups.env ];
      ports = [
        "82:6543/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # Dashboard website
    dash = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; };
      volumes = [
        "/data/local/docker/config/dash/other.json:/web/other.json:ro"
      ];
      ports = [
        "80:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # DNS updater
    noip = rec {
      image = imageFile.imageName;
      imageFile = my.containers.udns;
      environmentFiles = [ /data/local/safe/udns.env ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # Matrix server
#    matrix = {
#      image = "matrixdotorg/synapse:latest";
#      environment = {
#        TZ = my.config.system.timezone;
#        UID = builtins.toString my.config.user.uid;
#        GID = builtins.toString my.config.user.gid;
#        SYNAPSE_REPORT_STATS = "no";
#      };
#      volumes = [
#        "/data/local/docker/config/synapse:/data"
#      ];
#      ports = [
#        "83:8008/tcp"
#      ];
#      extraOptions = [ "--dns=172.17.0.1" ];
#    };

    # Asterisk container
    asterisk = rec {
      image = imageFile.imageName;
      imageFile = my.containers.asterisk;
      volumes = [
        "/data/local/docker/config/asterisk/conf:/etc/asterisk/conf.mine"
        "/data/local/docker/config/asterisk/voicemail:/var/spool/asterisk/voicemail"
        "/data/local/docker/config/asterisk/record:/var/spool/asterisk/monitor"
        "/data/local/docker/config/asterisk/sounds:/var/lib/asterisk/sounds/mine"
        # Email files
        "/data/local/mail:/data/local/mail:ro"
        "/etc/msmtprc:/etc/msmtprc:ro"
      ];
      extraOptions = [ "--dns=172.17.0.1" "--network=host" ];
    };
    # Asterisk HTTP Server for users
    http-asterisk-user = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      volumes = [
        "/data/local/docker/config/asterisk/voicemail:/web/voicemail:ro"
        "/data/local/docker/config/asterisk/record:/web/monitor:ro"
      ];
      ports = [
        "8080:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };
    # Asterisk HTTP Server for kodi
    http-asterisk-kodi = rec {
      image = "halverneus/static-file-server:latest";
      volumes = [
        "/data/local/docker/config/asterisk/voicemail:/web/voicemail:ro"
        "/data/local/docker/config/asterisk/record:/web/monitor:ro"
      ];
      ports = [
        "8081:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # HTTP Server manuals
    man-nix = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      volumes = [
        "${pkgs.nix.doc}/share/doc/nix/manual:/web:ro"
      ];
      ports = [
        "8090:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };
    man-nixos = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      volumes = [
        "${config.system.build.manual.manualHTML}/share/doc/nixos:/web:ro"
      ];
      ports = [
        "8091:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

  };

  fileSystems."/" =
    { device = "vimmer/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B7F0-3A34";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "vimmer/home";
      fsType = "zfs";
    };

  fileSystems."/data/vms" =
    { device = "vimmer/vms";
      fsType = "zfs";
    };

  fileSystems."/data/local" =
    { device = "vimmer/data";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "vimmer/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "vimmer/tmp";
      fsType = "zfs";
    };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
