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

    # HTTP Server manuals
    mannix = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      volumes = [
        "${pkgs.nix.doc}/share/doc/nix/manual:/web:ro"
      ];
      ports = [
        "84:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };
    mannixos = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      volumes = [
        "${config.system.build.manual.manualHTML}/share/doc/nixos:/web:ro"
      ];
      ports = [
        "85:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # HTTP Server for users
    httpd = rec {
      image = imageFile.imageName;
      imageFile = my.containers.web {};
      volumes = [
        "/data/local/docker/config/asterisk/voicemail:/web/voicemail:ro"
        "/data/local/docker/config/asterisk/record:/web/monitor:ro"
      ];
      ports = [
        "83:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # HTTP Server for kodi
    httpk = rec {
      image = "halverneus/static-file-server:latest";
      volumes = [
        "/data/local/docker/config/asterisk/voicemail:/web/voicemail:ro"
        "/data/local/docker/config/asterisk/record:/web/monitor:ro"
      ];
      ports = [
        "82:8080/tcp"
      ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # DNS updater
    udns = rec {
      image = imageFile.imageName;
      imageFile = my.containers.udns;
      environmentFiles = [ /data/local/safe/udns.env ];
      extraOptions = [ "--dns=172.17.0.1" ];
    };

    # DNS Server
    adblock = {
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

    # Shadow Socks server
    shadow = {
      image = "shadowsocks/shadowsocks-libev";
      environment = {
        METHOD = "aes-256-gcm";
        DNS_ADDRS = "172.17.0.1";
      };
      environmentFiles = [ /data/local/safe/shadow.env ];
      ports = [
        "8388:8388/tcp"
      ];
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
